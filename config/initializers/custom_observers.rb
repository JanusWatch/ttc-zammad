Rails.application.config.after_initialize do
  require_dependency Rails.root.join('lib/custom_observer/ticket_company_observer.rb')
  ActiveRecord::Base.observers << CustomObserver::TicketCompanyObserver
  ActiveRecord::Base.instantiate_observers
end
