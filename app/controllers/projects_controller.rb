# frozen_string_literal: true

class ProjectsController < ApplicationController
  before_action :set_project, only: [ :show, :update, :destroy ]

  def index
    @projects = Project.includes(:project_tasks).recent
    @projects = @projects.where(status: params[:status]) if params[:status].present?

    render json: @projects.map { |p| format_project(p) }
  end

  def show
    render json: format_project(@project, include_tasks: true)
  end

  def create
    @project = Project.new(project_params)
    if @project.save
      render json: format_project(@project), status: :created
    else
      render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @project.update(project_params)
      render json: format_project(@project)
    else
      render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    head :no_content
  end

  def stats
    render json: {
      total: Project.count,
      active: Project.where(status: "active").count,
      planning: Project.where(status: "planning").count,
      completed: Project.where(status: "completed").count,
      total_tasks: ProjectTask.count,
      completed_tasks: ProjectTask.where(status: %w[completed done]).count
    }
  end

  private

  def set_project
    @project = Project.includes(:project_tasks).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Project not found" }, status: :not_found
  end

  def project_params
    params.require(:project).permit(:name, :description, :status, :progress, :priority, :start_date, :end_date, :budget, :spent)
  end

  def format_project(project, include_tasks: false)
    data = {
      id: project.id,
      name: project.name,
      description: project.description,
      status: project.status,
      progress: project.progress,
      priority: project.priority,
      start_date: project.start_date&.iso8601,
      end_date: project.end_date&.iso8601,
      budget: project.budget,
      spent: project.spent,
      tasks_completed: project.tasks_completed_count,
      tasks_total: project.tasks_total_count,
      created_at: project.created_at,
      updated_at: project.updated_at
    }
    if include_tasks
      data[:tasks] = project.project_tasks.map { |t| format_task(t) }
    end
    data
  end

  def format_task(task)
    {
      id: task.id,
      project_id: task.project_id,
      title: task.title,
      description: task.description,
      status: task.status,
      priority: task.priority,
      assignee: task.assignee_display_name,
      employee_id: task.employee_id,
      due_date: task.due_date&.iso8601,
      story_points: task.story_points,
      sprint_name: task.sprint_name,
      tags: task.tags || []
    }
  end
end
