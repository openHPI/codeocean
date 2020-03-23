module Admin
  class DashboardPolicy < AdminOnlyPolicy
    def dump_docker?
      admin?
    end
  end
end
