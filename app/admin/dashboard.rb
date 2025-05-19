ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do

    columns do
      column do
        panel "User Statistics", style: "background: linear-gradient(to right, #e0f7fa, #ffffff); padding: 20px; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);" do
          div style: "font-weight: bold; font-size: 16px; margin-bottom: 8px;" do
            "Total Users: #{User.where(role: 'user').count}"
          end
          div style: "font-weight: bold; font-size: 16px; margin-bottom: 8px;" do
            "Total Admins: #{AdminUser.count}"
          end
          div style: "font-weight: bold; font-size: 16px; margin-bottom: 8px;" do
            "Total Supervisors: #{User.where(role: 'supervisor').count}"
          end
          div style: "font-weight: bold; font-size: 16px;" do
            "All Users Combined: #{User.count + AdminUser.count}"
          end
        end
      end

      column do
        panel "User Distribution", style: "background: #fff7e6; padding: 20px; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);" do
          pie_chart(
            {
              "Users" => User.where(role: 'user').count,
              "Admins" => AdminUser.count,
              "Supervisors" => User.where(role: 'supervisor').count
            },
            donut: true,
            legend: "bottom",
            colors: ["#4fc3f7", "#81c784", "#ffb74d"]
          )
        end
      end
    end

    columns do
      column do
        panel " Movie Statistics", style: "background: #e3f2fd; padding: 20px; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);" do
          div style: "font-weight: bold; font-size: 16px; margin-bottom: 10px;" do
            "Total Movies: #{Movie.count}"
          end
          div do
            link_to("Fetch All Movies (API)", "/api/v1/movies/all", target: "_blank", style: "text-decoration: underline; color: #1565c0;")
          end
        end
      end

      column do
        panel " Quick Links", style: "background: #e8f5e9; padding: 20px; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);" do
          ul style: "list-style: none; padding-left: 0;" do
            li do
              link_to "View All Users", admin_users_path, style: "color: #2e7d32; font-weight: bold;"
            end
            li do
              link_to " Add New User", new_admin_user_path, style: "color: #2e7d32; font-weight: bold;"
            end
          end
        end
      end
    end

    panel "Subscriptions by Plan", style: "background: #fdfdfd; padding: 20px; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.05); margin-top: 20px;" do
      ul style: "font-size: 15px;" do
        Subscription.group(:plan).count.each do |plan, count|
          li "#{plan.capitalize} Plan: #{count} subscriptions", style: "margin-bottom: 5px;"
        end
      end
    end
  end
end
