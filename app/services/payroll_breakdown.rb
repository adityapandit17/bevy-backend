class PayrollBreakdown
  Result = Struct.new(
    :basic,
    :hra,
    :allowances,
    :bonus,
    :pf,
    :esi,
    :professional_tax,
    :income_tax,
    :deductions,
    :gross,
    :net,
    :effective_from,
    keyword_init: true
  )

  class << self
    def for_employee(employee, month:)
      structure = latest_structure_for(employee, month)
      new(structure)
    end

    def latest_structure_for(employee, month)
      return nil if employee.nil?

      cutoff = PayrollMonth.parse(month).end_of_month
      structure = employee.salary_structures
                           .where("effective_from IS NULL OR effective_from <= ?", cutoff)
                           .order(effective_from: :desc, created_at: :desc)
                           .first

      # If no structure exists before cutoff, fall back to default structure for that month
      structure || SalaryStructure.for_month(employee, cutoff.year, cutoff.month)
    end
  end

  def initialize(structure)
    @structure = structure
  end

  def present?
    @structure.present?
  end

  def monthly
    return nil unless present?
    result_for(divisor: 12)
  end

  def annual
    return nil unless present?
    result_for(divisor: 1)
  end

  private

  def result_for(divisor:)
    return nil if @structure.nil?
    
    basic = normalize(@structure.basic, divisor)
    hra = normalize(@structure.hra, divisor)
    other_allowances = normalize(@structure.allowances, divisor)
    bonus = normalize(@structure.bonus, divisor)
    # Combine annual bonus + other allowances into total allowances
    allowances = other_allowances + bonus
    pf = normalize(@structure.pf, divisor)
    esi = normalize(@structure.esi, divisor)
    professional_tax = normalize(@structure.professional_tax, divisor)
    income_tax = normalize(@structure.income_tax, divisor)
    deductions = normalize(@structure.deductions, divisor)

    gross = basic + hra + allowances
    statutory = pf + esi + professional_tax + income_tax
    total_deductions = deductions + statutory
    net = gross - total_deductions

    Result.new(
      basic: basic,
      hra: hra,
      allowances: allowances,
      bonus: 0, # Bonus is now included in allowances
      pf: pf,
      esi: esi,
      professional_tax: professional_tax,
      income_tax: income_tax,
      deductions: deductions,
      gross: gross,
      net: net,
      effective_from: @structure.effective_from
    )
  end

  def normalize(value, divisor)
    return BigDecimal("0") if value.nil?
    decimal = value.is_a?(BigDecimal) ? value : BigDecimal(value.to_s)
    divisor.positive? ? decimal / divisor : decimal
  end
end

