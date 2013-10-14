class BibliographiesController < ApplicationController


  # permissoes


  def list
    @bibliographies = Bibliography.all_by_allocation_tags(AllocationTag.find_related_ids(active_tab[:url][:allocation_tag_id])) # sempre dentro de uma UC

    respond_to do |format|
      format.html
      format.json { render json: @bibliographies }
    end
  end

  # GET /bibliographies
  # GET /bibliographies.json
  def index
    @bibliographies = Bibliography.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @bibliographies }
    end
  end

  # GET /bibliographies/1
  # GET /bibliographies/1.json
  def show
    @bibliography = Bibliography.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @bibliography }
    end
  end

  # GET /bibliographies/new
  # GET /bibliographies/new.json
  def new
    @bibliography = Bibliography.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @bibliography }
    end
  end

  # GET /bibliographies/1/edit
  def edit
    @bibliography = Bibliography.find(params[:id])
  end

  # POST /bibliographies
  # POST /bibliographies.json
  def create
    @bibliography = Bibliography.new(params[:bibliography])

    respond_to do |format|
      if @bibliography.save
        format.html { redirect_to @bibliography, notice: 'Bibliography was successfully created.' }
        format.json { render json: @bibliography, status: :created, location: @bibliography }
      else
        format.html { render action: "new" }
        format.json { render json: @bibliography.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /bibliographies/1
  # PUT /bibliographies/1.json
  def update
    @bibliography = Bibliography.find(params[:id])

    respond_to do |format|
      if @bibliography.update_attributes(params[:bibliography])
        format.html { redirect_to @bibliography, notice: 'Bibliography was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @bibliography.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /bibliographies/1
  # DELETE /bibliographies/1.json
  def destroy
    @bibliography = Bibliography.find(params[:id])
    @bibliography.destroy

    respond_to do |format|
      format.html { redirect_to bibliographies_url }
      format.json { head :no_content }
    end
  end
end
