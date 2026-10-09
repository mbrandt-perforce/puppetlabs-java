# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'java class configuration' do
  context 'with a Debian-family host', if: os[:family].casecmp('Debian').zero? do
    let(:java_version) do
      case os[:release][:major].to_s
      when '13', '26.04' then '21'
      when '12', '24.04' then '17'
      else '11'
      end
    end

    let(:java_home) { "/usr/lib/jvm/java-1.#{java_version}.0-openjdk-amd64/" }
    let(:alternative) { "java-1.#{java_version}.0-openjdk-amd64" }
    let(:install_java) do
      <<~MANIFEST
        class { 'java':
          package               => 'openjdk-#{java_version}-jdk',
          package_options       => ['--no-install-recommends'],
          java_alternative      => '#{alternative}',
          java_alternative_path => '#{java_home}bin/java',
          java_home             => '#{java_home}',
        }
      MANIFEST
    end

    it 'applies package options, selects the Java alternative, and configures JAVA_HOME' do
      idempotent_apply(install_java)

      result = shell("grep -Fx 'JAVA_HOME=#{java_home}' /etc/environment")
      expect(result.exit_code).to eq(0)

      result = shell("test \"$(readlink -f /etc/alternatives/java)\" = '#{java_home}bin/java'")
      expect(result.exit_code).to eq(0)
    end
  end
end
