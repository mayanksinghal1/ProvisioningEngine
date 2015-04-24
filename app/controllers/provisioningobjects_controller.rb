class ProvisioningobjectsController < ApplicationController
  before_action :set_provisioningobject, only: [:show, :edit, :update, :destroy, :deprovision, :provision]
  before_action :set_provisioningobjects, only: [:index]


  def ro
    'readonly'
  end

  def rw
    'readwrite'
  end

  # POST /customers
  # POST /customers.json
  def create
    # in the individual object's controller, the following needs to be done (here the example of a customers_controller:
    ## TODO: the next 2 lines are still needed. Is this the right place to control, whether a param is ro or rw?
    #@myparams = {"id"=>'ro', "name"=>rw, "created_at"=>'', "language"=>'showLanguageDropDown', "updated_at"=>'', "status"=>'', "target_id"=>'showTargetDropDown'}
#
    #@provisioningobject = Customer.new(customer_params)
    #@customer = @provisioningobject
    #@className = @provisioningobject.class.to_s
#abort @provisioningobject.inspect

    respond_to do |format|         
      if @provisioningobject.save
        if @provisioningobject.provisioningtime == Provisioningobject::PROVISIONINGTIME_IMMEDIATE && @provisioningobject.provision(:create)
          @notice = "#{@provisioningobject.class.name} is being created (provisioning running in the background)."
        else
          @notice = "#{@provisioningobject.class.name} is created and can be provisioned ad hoc."
        end
        format.html { redirect_to @provisioningobject, notice: @notice }
        format.json { render :show, status: :created, location: @provisioningobject } 
      else
        format.html { render :new  }                   
        format.json { render json: @provisioningobject.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /customers/1
  # PATCH/PUT /customers/1.json
  def update
    # individual settings are done e.g. in customers_controller.rb#update
    respond_to do |format|
      if @provisioningobject.update(provisioningobject_params)
        format.html { redirect_to @provisioningobject, notice: "#{@provisioningobject.class.name} was successfully updated." }
        format.json { render :show, status: :ok, location: @provisioningobject }
        format.js
      else
        format.html { render :edit }
        format.json { render json: @provisioningobject.errors, status: :unprocessable_entity }
        format.js
      end
    end
  end

  # PATCH /customers/1/deprovision
  # PATCH /customers/1/deprovision.json
  def deprovision
    # individual settings are done e.g. in customers_controller.rb#deprovision

    # default setting:
    async = true if async.nil?
    className = @provisioningobject.class.name

    if @provisioningobject.activeJob?
      flash[:error] = "#{className} #{@provisioningobject.name} cannot be de-provisioned: has active jobs running: see below."
      redirectPath = provisioningobject_provisionings_path

    elsif @provisioningobject.provisioned?
      flash[:notice] = "#{className} #{@provisioningobject.name} is being de-provisioned."
      redirectPath = :back
      
      @provisioningobject.provision(:destroy)
    else
      flash[:error] = "#{className} #{@provisioningobject.name} cannot be destroyed: is not provisioned."
      redirectPath = :back
      
    end 
    
    respond_to do |format|
      format.html { redirect_to redirectPath }
      format.json { head :no_content }
    end

  end

  # DELETE /customers/1
  # DELETE /customers/1.json
  def destroy(deprovision = true)
    # individual settings are done e.g. in customers_controller.rb#deprovision
    
    if @provisioningobject.provisioned?
      if deprovision
        @provisioningobject.provision(:destroy)
        flash[:success] = "#{@provisioningobject.class.name} #{@provisioningobject.name} is being de-provisioned."
        #redirectPath = :back
      else
        flash[:alert] = "#{@provisioningobject.class.name} #{@provisioningobject.name} is deleted from the database, but note that it might be is still configured on a target system."
        #flash[:success] = "#{@provisioningobject.class.name} #{@provisioningobject.name} is deleted, but note that it might be is still configured on a target system."
      end
      
    else
      flash[:success] = "#{@provisioningobject.class.name} #{@provisioningobject.name} deleted."
      @provisioningobject.destroy!
      
    end 

    
    respond_to do |format|
      format.html { redirect_to @redirectPath }
      format.json { head :no_content }
    end

   # from http://tools.ietf.org/html/rfc7231#section-4.3:
   #If a DELETE method is successfully applied, the origin server SHOULD
   #send a 202 (Accepted) status code if the action will likely succeed
   #but has not yet been enacted, a 204 (No Content) status code if the
   #action has been enacted and no further information is to be supplied,
   #or a 200 (OK) status code if the action has been enacted and the
   #response message includes a representation describing the status.

  end

  # allow for a possibility to remove all provisionins using a single button press:
  # see http://stackoverflow.com/questions/21489528/unable-to-delete-all-records-in-rails-4-through-link-to
  def removeAll
    # individual settings are done e.g. in customers_controller.rb#removeAll
    
    @provisioningobjects.each do |provisioningobject| 
      provisioningobject.destroy
    end
    flash[:notice] = "All #{@provisioningobject.class.name} have been deleted."
    redirect_to @redirectPath
  end

  # PATCH /customers/1/synchronize
  # -> find single customer on target and synchronize the data to the local database
  # PATCH /customers/synchronize
  # -> find all customers of all known target (i.e. targets found in the local database), and synchronize them to the local database
  def synchronize
    # individual settings are done e.g. in customers_controller.rb#deprovision
    @partentTargets = nil if @partentTargets.nil? 

    @async_all = false if @async_all.nil?
    @async_individual = false if @async_individual.nil?
#abort @async_all.inspect

    @recursive_all = false if @recursive_all.nil?
    @recursive_individual = true if @recursive_individual.nil?

    if @async_all
      being_all = "being "
    else
      being_all = ""
    end

    if @async_individual
      being_individual = "being "
    else
      being_individual = ""
    end


    #@id = params[:id]
    		#abort @id.inspect if @id != params[:id]

    if @id.nil?
      # PATCH /customers/synchronize
      # synchronizeAll:
      #Customer.synchronizeAll(@partentTargets, @async_all,  @recursive_all)
      @myClass.synchronizeAll(@partentTargets, @async_all,  @recursive_all)
      redirect_to :back, notice: "All #{@myClass.name.pluralize} are #{being_all}synchronized."
    else
      # PATCH /customers/1/synchronize
      @provisioningobject = @myClass.find(@id)
      @provisioningobject.synchronize(@async_individual, @recursive_individual)
      redirect_to :back, notice: "#{@provisioningobject.class.name} #{@provisioningobject.name} is #{being_individual}synchronized."
    end
  end

  # PATCH	/customers/1/provision
  def provision
    # individual settings are done e.g. in customers_controller.rb#provision

    #default values:
    @async = true if @async.nil?

    respond_to do |format|
      if @provisioningobject.provision(:create, async)
        format.html { redirect_to :back, notice: "#{@provisioningobject.class.name} #{@provisioningobject.name} is being provisioned to target system(s)" }
        format.json { render :show, status: :ok, location: @provisioningobject }
      else
        format.html { redirect_to :back, notice: "#{@provisioningobject.class.name} #{@provisioningobject.name} could not be provisioned to target system(s)" }
        format.json { render json: @provisioningobject.errors, status: :unprocessable_entity }
      end # if
    end # do
  end # def provision

end