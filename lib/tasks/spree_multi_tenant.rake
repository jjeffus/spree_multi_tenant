
def do_create_tenant domain, code
  if domain.blank? or code.blank?
    puts "Error: domain and code must be specified"
    puts "(e.g. rake spree_multi_tenant:create_tenant domain=mydomain.com code=mydomain)"
    exit
  end

  tenant = Spree::Tenant.create!({:domain => domain.dup, :code => code.dup})
  tenant.create_template_and_assets_paths
  tenant
end


namespace :spree_multi_tenant do

  desc "Create a new tenant and assign all exisiting items to the tenant."
  task :create_tenant_and_assign => :environment do
    tenant = do_create_tenant ENV["domain"], ENV["code"]

    # Assign all existing items to the new tenant
    SpreeMultiTenant.tenanted_models.each do |model|
      model.all.each do |item|
        item.update_attribute(:tenant_id, tenant.id)
      end
    end
  end

  desc "Create a new tenant"
  task :create_tenant => :environment do
    tenant = do_create_tenant ENV["domain"], ENV["code"]
  end

  desc "Create a new admin user for tenant"
  task :add_user => :environment do
    tenant_name     = ENV['tenant']
    email          = ENV["email"]
    password       = ENV["password"]
    tenant = Spree::Tenant.find_by(code: tenant_name)
    if tenant == nil
      say "\nWARNING: There is no tenant with name #{name}, so no account changes were made."
      exit
    end
    if Spree::User.find_by_email(email)
      say "\nWARNING: There is already a user with the email: #{email}, so no account changes were made."
    else
      attributes = {
        :password => password,
        :password_confirmation => password,
        :email => email,
        :login => email
      }

      admin = Spree::User.new(attributes)
      if admin.save
        role = Spree::Role.find_or_create_by(name: 'admin')
        admin.spree_roles << role
        admin.tenant_id = tenant.id
        admin.save
        admin.generate_spree_api_key!
        say "Done!"
      else
        say "There was some problems with persisting new admin user:"
        admin.errors.full_messages.each do |error|
          say error
        end
      end
    end
  end

end
