class FileTypePolicy < AdminOnlyPolicy
  [:index?, :show?].each do |action|
    define_method(action) { admin? || teacher? }
  end

end
