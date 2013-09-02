require 'lebops'
require 'rails'
module Lebops
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/lebops.rake"
    end
  end
end