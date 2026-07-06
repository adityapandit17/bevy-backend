# frozen_string_literal: true

class ProjectTasksController < ApplicationController
  before_action :set_project_task, only: [ :show, :update, :destroy ]

  def index
    tasks = ProjectTask.includes(:employee, :project).by_project(params[:project_id]).by_status(params[:status]).by_sprint(params[:sprint_name])
    render json: tasks.map { |t| format_task(t) }
  end

  def show
    render json: format_task(@project_task)
  end

  def create
    task = ProjectTask.new(project_task_params)
    if task.save
      render json: format_task(task), status: :created
    else
      render json: { errors: task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @project_task.update(project_task_params)
      render json: format_task(@project_task)
    else
      render json: { errors: @project_task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @project_task.destroy
    head :no_content
  end

  def sprints
    names = ProjectTask.where.not(sprint_name: [ nil, "" ]).distinct.pluck(:sprint_name)
    sprints = names.map do |name|
      tasks = ProjectTask.where(sprint_name: name)
      {
        name: name,
        total_tasks: tasks.count,
        completed_tasks: tasks.where(status: %w[completed done]).count,
        story_points: tasks.sum(:story_points)
      }
    end
    render json: sprints
  end

  private

  def set_project_task
    @project_task = ProjectTask.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Task not found" }, status: :not_found
  end

  def project_task_params
    params.require(:project_task).permit(
      :project_id, :title, :description, :status, :priority,
      :employee_id, :assignee_name, :due_date, :story_points, :sprint_name, tags: []
    )
  end

  def format_task(task)
    {
      id: task.id,
      project_id: task.project_id,
      project_name: task.project&.name,
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
