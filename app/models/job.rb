class Job 


 #retorna uma lista de Jobs não enviados quer podem ser enviados
 #soma a quantidade a ser enviada com a quantidade enviada nos ultimos 30 minutos
 #altera o status dos Jobs que seram enviados
 #quantidade maxima de email que pode ser enviado é 500 está setado no select do update  
 #O tempo de espera está setado no select como 30 minutos (interval '30 minute')
 #Exemplo de como enviar pacote com 3 email a cada dois minutos
    #altera o tempo de 30 minutos do select para 2 minutos
    #alterar o valor 500 do select do update para 3
    #alterar o max_size do metodo send_mass_email para 3
    #alterar o scheduler para roda a cada 2 minutos
    #PARA O PROCESSO DO DELAYED JOB: script/delayed_job stop
  def self.select_and_update_status_jobs_not_send
    Delayed::Job.find_by_sql <<-SQL
        WITH RECURSIVE delayed_job(id, amount, total) AS (
          SELECT
            id, amount, 
            (SELECT SUM(dj2.amount) + 
            (SELECT CASE WHEN (SUM(dj.amount) IS NULL OR SUM(dj.amount)<1) THEN 0 ELSE SUM(dj.amount) END FROM delayed_jobs dj WHERE dj.status = true AND dj.created_at >= (now() - interval '30 minute'))
            FROM delayed_jobs dj2 WHERE dj2.id <= dj1.id AND dj2.status = false) AS total
          FROM delayed_jobs dj1 WHERE dj1.status = false ORDER BY id ASC
        )
        UPDATE delayed_jobs SET status = true WHERE id IN (SELECT id from delayed_job WHERE total<=500) RETURNING *;
    SQL
  end  

  def self.delete_jobs
    Delayed::Job.where("status = true AND created_at < (now() - interval '30 minute')").delete_all
  end  

  def self.send_mass_email(emails, subject, new_msg_template, files, email)
    #blocos de emails
    max_size = 500
    emails_in_jobs = emails.in_groups_of(max_size, false).to_a

    emails_in_jobs.each do |e|
      job = Notifier.delay.send_mail(e, subject, new_msg_template, files, email)
      job.amount = e.count
      job.save!

    end
    Job.job_send_mail 
  end

  #Envia e-mail e salva um clone no banco de dados
  #O clone fica no banco de dados por 30 minutos depois o metodo delete_jobs apaga
  def self.job_send_mail
    jobs = Job.select_and_update_status_jobs_not_send
    jobs.each do |job|
      clone_job = job.dup
      Delayed::Worker.new.run(job) 
      clone_job.save!
    end
    
    Job.delete_jobs
  end 

end
