class CoursesController < ApplicationController

  load_and_authorize_resource
  
   def index
   @courses = Course.find(:all) 
   respond_to do |format| 
     format.html # index.html.erb format.xml { render :xml => @posts } end
   end
  end

  def show
    @course = Course.find(params[:id])
    
    respond_to do |format|
      format.html
      format.xml  { render :xml => @course }
    end
  end

  def new
    respond_to do |format|
      
      format.html
      format.xml  { render :xml => @course }
    end
  end

  def edit
    @course = Course.find(params[:id])
  end

  def create 
    @course = Course.new(params[:course]) 
    respond_to do |format| 
      if @course.save flash[:notice] = 'Post was successfully created.' 
        format.html { redirect_to(@course) } 
        format.xml { render :xml => @course, :status => :created, :location => @course } 
      else format.html { render :action => "new" } 
        format.xml { render :xml => @course.errors, :status => :unprocessable_entity } 
      end 
    end 
  end
  

  def update
    @course = Course.find(params[:id])
    respond_to do |format| 
      if @course.update_attributes(params[:course])
        flash[:notice] = 'Post was successfully updated.' 
        format.html { redirect_to(@course) } 
        format.xml { head :ok } 
      else 
        format.html { render :action => "edit" } 
        format.xml { render :xml => @post.errors, :status => :unprocessable_entity } 
      end 
    end 
  end
  

  def destroy
    @course = Course.find(params[:id])
    @course.destroy

    respond_to do |format|
      format.html #{ redirect_to(users_url, :notice => 'Usuario excluido com sucesso!') }
      format.xml  { head :ok }
    end
  end

end