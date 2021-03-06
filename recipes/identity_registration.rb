#
# Cookbook Name:: openstack-nfv-orchestration
# Recipe:: identity_registration
#
# Copyright 2017, x-ion

require 'uri'

class ::Chef::Recipe
  include ::Openstack
end

identity_admin_endpoint = admin_endpoint 'identity'
interfaces = {
  public: { url: public_endpoint('nfv-orchestration') },
  internal: { url: internal_endpoint('nfv-orchestration') },
  admin: { url: admin_endpoint('nfv-orchestration') },
}
auth_url = ::URI.decode identity_admin_endpoint.to_s
service_pass = get_password 'service', 'openstack-nfv-orchestration'
service_user =
  node['openstack']['nfv-orchestration']['conf']['keystone_authtoken']['username']
service_role = node['openstack']['nfv-orchestration']['service_role']
service_project =
  node['openstack']['nfv-orchestration']['conf']['keystone_authtoken']['project_name']

region = node['openstack']['region']
admin_user = node['openstack']['identity']['admin_user']
admin_pass = get_password 'user', admin_user
admin_project = node['openstack']['identity']['admin_project']
admin_domain = node['openstack']['identity']['admin_domain_name']

connection_params = {
  openstack_auth_url:     "#{auth_url}/auth/tokens",
  openstack_username:     admin_user,
  openstack_api_key:      admin_pass,
  openstack_project_name: admin_project,
  openstack_domain_name:  admin_domain,
}

# Register NFV Orchestration Services
openstack_service 'tacker' do
  type 'nfv-orchestration'
  connection_params connection_params
end

interfaces.each do |interface, res|
  # Register NFV Orchestration Endpoints
  openstack_endpoint 'nfv-orchestration' do
    service_name 'tacker'
    interface interface.to_s
    url res[:url].to_s
    region region
    connection_params connection_params
  end
end

# Register Service Project
openstack_project service_project do
  connection_params connection_params
end

advanced_services_role = 'advsvc'
openstack_role advanced_services_role do
  connection_params connection_params
end

# Register Service User
openstack_user service_user do
  project_name service_project
  password service_pass
  connection_params connection_params
end

# Grant Service role to Service User for Service Project
openstack_user service_user do
  role_name service_role
  project_name service_project
  connection_params connection_params
  action :grant_role
end

# Grant Advanced Service role to Service User for Service Project
openstack_user service_user do
  role_name advanced_services_role
  project_name service_project
  connection_params connection_params
  action :grant_role
end
