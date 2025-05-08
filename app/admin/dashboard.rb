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
        panel "Movie Statistics", style: "background-color: #e6f0fa; padding: 20px; border-radius: 10px;" do
          para "Total Movies: #{Movie.count}", style: "font-weight: bold;"
          para link_to("Fetch All Movies (API)", "/api/v1/movies/all", target: "_blank")
        end
      end

      column do
        panel "Quick Links", style: "background-color: #e6ffe6; padding: 20px; border-radius: 10px;" do
          ul do
            li link_to "View All Users", admin_users_path
            li link_to "Add New User", new_admin_user_path
          end
        end
      end
    end

    panel "Subscription Count by Plan", style: "background-color: #f9f9f9; padding: 20px; border-radius: 10px;" do
      ul do
        Subscription.group(:plan).count.each do |plan, count|
          li "#{plan.capitalize} Plan: #{count} subscriptions"
        end
      end
    end

  end
end