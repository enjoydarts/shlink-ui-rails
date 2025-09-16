class ClearFinishedJobsJob < ApplicationJob
  queue_as :default

  def perform
    SolidQueue::Job.clear_finished_in_batches(sleep_between_batches: 0.3)
  end
end