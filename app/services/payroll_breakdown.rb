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
    result_for(divisor: 12)
  end

  def annual
    result_for(divisor: 1)
  end

  private

  def result_for(divisor:)
    basic = normalize(@structure&.basic, divisor)
    hra = normalize(@structure&.hra, divisor)
    allowances = normalize(@structure&.allowances, divisor)
    bonus = normalize(@structure&.bonus, divisor)
    pf = normalize(@structure&.pf, divisor)
    esi = normalize(@structure&.esi, divisor)
    professional_tax = normalize(@structure&.professional_tax, divisor)
    income_tax = normalize(@structure&.income_tax, divisor)
    deductions = normalize(@structure&.deductions, divisor)

    gross = basic + hra + allowances + bonus
    statutory = pf + esi + professional_tax + income_tax
    total_deductions = deductions + statutory
    net = gross - total_deductions

    Result.new(
      basic: basic,
      hra: hra,
      allowances: allowances,
      bonus: bonus,
      pf: pf,
      esi: esi,
      professional_tax: professional_tax,
      income_tax: income_tax,
      deductions: deductions,
      gross: gross,
      net: net,
      effective_from: @structure&.effective_from
    )
  end

  def normalize(value, divisor)
    decimal = BigDecimal(value || 0)
    divisor.positive? ? decimal / divisor : decimal
  end
end

