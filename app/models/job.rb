class Job 

  #retorna a quantidade de jobs da lista dos ultimos 30 minutos quer foram enviados
  def self.count_jobs_30_minute
    total = Delayed::Job.where("status = true AND created_at >= (now() - interval '30 minute')").select('SUM(amount) AS amount').first
    total.amount.nil? ? 0 : total.amount
  end 

  def self.delete_jobs
    Delayed::Job.where("status = true AND created_at < (now() - interval '30 minute')").delete_all
  end  

  def self.list_jobs_not_send
    Delayed::Job.where("status = false").order('id ASC')
  end  

  def self.update_status_job(job)
    job.status = true
    job.save!
  end

end
