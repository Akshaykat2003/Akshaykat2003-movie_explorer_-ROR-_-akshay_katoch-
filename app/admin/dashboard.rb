ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do

    columns do
      column do
        panel "User Statistics", style: "background-color: #f0f8ff; padding: 20px; border-radius: 10px;" do
          para "Total Users: #{User.where(role: 'user').count}", style: "font-weight: bold;"
          para "Total Admins: #{AdminUser.count}", style: "font-weight: bold;"
          para "Total Supervisors: #{User.where(role: 'supervisor').count}", style: "font-weight: bold;"
          para "Total All Users: #{User.count + AdminUser.count}", style: "font-weight: bold;"
        end
      end

      column do
        panel "User Distribution Chart" do
          pie_chart(
            {
              "Users" => User.where(role: 'user').count,
              "Admins" => AdminUser.count,
              "Supervisors" => User.where(role: 'supervisor').count
            },
            donut: true,
            legend: "bottom"
          )
        end
      end
    end

    columns do
      column do
        panel "Quick Links", style: "background-color: #e6ffe6; padding: 20px; border-radius: 10px;" do
          ul do
            li link_to "View All Users", admin_users_path
            li link_to "Add New User", new_admin_user_path
          end
        end
      end
    end

    # # Subscription Table Overview
    # panel "User Subscriptions Overview", style: "background-color: #fff0f5; padding: 20px; border-radius: 10px;" do
    #   table_for Subscription.includes(:user).order(created_at: :desc).limit(10) do
    #     column("User") { |subscription| link_to(subscription.user.email, admin_user_path(subscription.user)) }
    #     column("Plan") { |subscription| subscription.plan.capitalize }
    #     column("Status") { |subscription| status_tag(subscription.status) }
    #     column("Expiry Date", &:expiry_date)
    #     column("Actions") do |subscription|
    #       link_to("View", admin_subscription_path(subscription))
    #     end
    #   end
    #   div do
    #     link_to "View All Subscriptions", admin_subscriptions_path, style: "display:block; margin-top:10px; font-weight:bold;"
    #   end
    # end

  
    panel "Subscription Count by Plan", style: "background-color: #f9f9f9; padding: 20px; border-radius: 10px;" do
      ul do
        Subscription.group(:plan).count.each do |plan, count|
          li "#{plan.capitalize} Plan: #{count} subscriptions"
        end
      end
    end

  end
end
