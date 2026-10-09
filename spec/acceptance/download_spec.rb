# frozen_string_literal: true

require 'spec_helper_acceptance'

download_dir = '/opt/java-acceptance-download'
download_versions = {
  'JAVA_DOWNLOAD_TAR_GZ_URL' => 'tar.gz',
  'JAVA_DOWNLOAD_RPM_URL' => 'rpm',
  'JAVA_DOWNLOAD_RPMBIN_URL' => 'rpmbin',
}

describe 'java::download' do
  download_versions.each do |url_variable, package_type|
    context "with #{package_type} package", if: ENV[url_variable] do
      if package_type == 'tar.gz'
        next unless os[:family].casecmp('Debian').zero?
      else
        next unless os[:family].casecmp('RedHat').zero?
      end

      it 'downloads, installs, and links Java with optional credentials, proxy, and JCE' do
        jce_url = ENV['JAVA_DOWNLOAD_JCE_URL']
        jce_parameters = if jce_url
                           <<~PARAMETERS
                             jce          => true,
                             jce_url      => '#{jce_url}',
                             jce_username => '#{ENV.fetch('JAVA_DOWNLOAD_JCE_USERNAME', '')}',
                             jce_password => '#{ENV.fetch('JAVA_DOWNLOAD_JCE_PASSWORD', '')}',
                           PARAMETERS
                         else
                           ''
                         end
        proxy_parameters = if ENV['JAVA_DOWNLOAD_PROXY_SERVER']
                             <<~PARAMETERS
                               proxy_server => '#{ENV.fetch('JAVA_DOWNLOAD_PROXY_SERVER')}',
                               proxy_type   => '#{ENV.fetch('JAVA_DOWNLOAD_PROXY_TYPE', 'https')}',
                             PARAMETERS
                           else
                             ''
                           end
        manifest = <<~MANIFEST
          java::download { 'acceptance_jdk':
            version        => '8',
            version_major  => '8u201',
            version_minor  => 'b09',
            java_se        => 'jdk',
            url            => '#{ENV.fetch(url_variable)}',
            username       => '#{ENV.fetch('JAVA_DOWNLOAD_USERNAME', '')}',
            password       => '#{ENV.fetch('JAVA_DOWNLOAD_PASSWORD', '')}',
            package_type   => '#{package_type}',
            basedir        => '#{download_dir}',
            manage_basedir => true,
            manage_symlink => true,
            symlink_name   => 'java_home',
            #{proxy_parameters}
            #{jce_parameters}
          }
        MANIFEST

        idempotent_apply(manifest)

        expect(shell("test -L '#{download_dir}/java_home'").exit_code).to eq(0)
        if jce_url
          policy_path = os[:family].casecmp('RedHat').zero? ? 'jdk1.8.0_201-amd64' : 'jdk1.8.0_201'
          expect(shell("test -f '#{download_dir}/#{policy_path}/jre/lib/security/US_export_policy.jar'").exit_code).to eq(0)
        end
      end
    end
  end
end
