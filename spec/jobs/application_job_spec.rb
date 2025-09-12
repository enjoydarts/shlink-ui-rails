# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationJob, type: :job do
  describe 'base job class' do
    it 'inherits from ActiveJob::Base' do
      expect(described_class.superclass).to eq(ActiveJob::Base)
    end

    it 'can be instantiated' do
      # Create a simple test job that inherits from ApplicationJob
      test_job_class = Class.new(ApplicationJob) do
        def perform
          # Test job implementation
        end
      end

      expect(test_job_class.new).to be_a(ApplicationJob)
    end
  end
end
