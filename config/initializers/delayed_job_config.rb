Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 60 # If no jobs are available, the worker sleeps for 60 second
Delayed::Worker.max_attempts = 3
Delayed::Worker.max_run_time = 5.minutes
Delayed::Worker.default_queue_name = 'default'
Delayed::Worker.raise_signal_exceptions = :term
Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'delayed_job.log'))
