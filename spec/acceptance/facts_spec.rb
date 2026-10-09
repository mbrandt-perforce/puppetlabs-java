# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'Java Facter facts' do
  it 'reports version, home, and JVM library facts after Java is installed' do
    idempotent_apply("class { 'java': }")

    java_version = shell('facter -p java_version').stdout.strip
    java_major_version = shell('facter -p java_major_version').stdout.strip
    java_patch_level = shell('facter -p java_patch_level').stdout.strip
    java_default_home = shell('facter -p java_default_home').stdout.strip
    java_libjvm_path = shell('facter -p java_libjvm_path').stdout.strip

    expect(java_version).to match(/\A(?:1\.)?\d+/)
    expect(java_major_version).to match(/\A\d+\z/)
    expect(java_patch_level).to match(/\A\d+\z/)
    expect(java_default_home).to start_with('/')
    expect(java_libjvm_path).to start_with('/')
    expect(shell("test -d '#{java_default_home}'").exit_code).to eq(0)
    expect(shell("test -f '#{java_libjvm_path}/libjvm.so'").exit_code).to eq(0)
  end
end
