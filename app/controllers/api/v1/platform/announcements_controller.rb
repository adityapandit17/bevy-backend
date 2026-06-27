# frozen_string_literal: true

module Api
  module V1
    module Platform
      class AnnouncementsController < BaseController
        before_action :set_announcement, only: [ :show, :update, :destroy ]

        def index
          render_success(PlatformAnnouncement.recent.map(&:platform_json))
        end

        def show
          render_success(@announcement.platform_json)
        end

        def create
          announcement = PlatformAnnouncement.new(announcement_params)
          announcement.platform_admin_user = current_platform_admin
          if announcement.save
            audit_action!(action: "announcement.create", resource: announcement, metadata: { title: announcement.title })
            render_success(announcement.platform_json, :created)
          else
            render_error(announcement.errors.full_messages.join(", "))
          end
        end

        def update
          if @announcement.update(announcement_params)
            audit_record_update!(action: "announcement.update", record: @announcement)
            render_success(@announcement.platform_json)
          else
            render_error(@announcement.errors.full_messages.join(", "))
          end
        end

        def destroy
          title = @announcement.title
          @announcement.destroy!
          audit_action!(action: "announcement.destroy", metadata: { title: title })
          render_success({ message: "Announcement deleted" })
        end

        private

        def set_announcement
          @announcement = PlatformAnnouncement.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render_error("Announcement not found", :not_found)
        end

        def announcement_params
          params.require(:announcement).permit(
            :title, :message, :audience, :status, :starts_at, :ends_at
          )
        end
      end
    end
  end
end
