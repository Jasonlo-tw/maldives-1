class FixedassetsController < ApplicationController
  include FixedassetsHelper
  def index
    #@fixedassets = Fixedasset.all.page(params[:page])
    @q = Fixedasset.search(params[:q])
    @fixedassets = @q.result.paginate(:page => params[:page])
    cookies[:last_fixedassets_paginated] = params[:page]
  end

  def get_file_names( path )
    
    files_by_ctime = {}
    Dir.chdir(path)
    Dir.entries(Dir.pwd).each do |f|
     # next if f == '.'
     # next if f == '..'
      next if f =~ /^\./    # ignore dot-files and dot-directories                                    

      full_filename = File.join( Dir.pwd , f)

      if File.directory?( full_filename )
        get_file_names( full_filename )
      else
        stat = File::Stat.new( full_filename )
        files_by_ctime[stat.ctime] ||= []
        files_by_ctime[stat.ctime] << full_filename
      end
    end
    Dir.chdir('..')
    return files_by_ctime
  end

  def do_print
    date = params['print_date']
    print_type = params['print_type']
    
    if date ==""
      year = DateTime.now.year
      month = DateTime.now.month
    else
      year = date[0..3]
      month = date[5..6]
    end
    
    if print_type == "1"
      based_on = params['optionsRadios']
      PrintServices.new(year.to_i,month.to_i,based_on).perform
      
      #Delayed::Job.enqueue PrintServices.new(year.to_i,month.to_i,based_on)
    elsif print_type == "2"
      based_on = params['optionsRadios']
      PrintServices3.new(year.to_i,month.to_i,based_on).perform
      #Delayed::Job.enqueue PrintServices3.new(year.to_i,month.to_i,based_on)
    elsif print_type == "3"
      #is_mortgaged = params['is_mortgaged']
      if (params['is_mortgaged'] == nil)
        is_mortgaged = false
      elsif (params['is_mortgaged'] == "checked")
        is_mortgaged = true
      end
      
      #PrintServices2.new.do_print(year.to_i, month.to_i)
      Delayed::Job.enqueue PrintServices2.new(year.to_i,month.to_i, is_mortgaged)
    end

    redirect_to reports_fixedassets_path
  end

  def reports
    Dir.chdir(Rails.root.to_s)
    @files_map =  get_file_names(Rails.root.to_s + "/public/fixedassets_pdf")  #Dir.glob('public/fixedassets/*')
    @files =  Dir.glob(Rails.root.to_s + "/public/fixedassets_pdf/*")

  end


  def show 
    @fixedasset = Fixedasset.find(params[:id])
    @fixedasset_changeds = @fixedasset.fixedasset_changeds
    @fixedasset_redepreciation = @fixedasset.fixedasset_redepreciation
  end

  def new 
    @fixedasset = Fixedasset.new
  end

  def create
    f_params = fixedasset_params 
    fixed_asset_id = f_params[:fixed_asset_id]
    f_params[:ab_type] = fixed_asset_id[0]
    f_params[:year] = fixed_asset_id[1..2].to_i
    f_params[:category_id] = fixed_asset_id[3].to_i
    f_params[:category_lv2] = fixed_asset_id[4]
    f_params[:serial_no] = fixed_asset_id[5..7].to_i
    f_params[:sequence_no] = fixed_asset_id[9..10].to_i
    #parse fixed_asset_id to ab_type, year, category_id, category_lv2, serial_no, sequene
    original_cost = f_params[:original_cost].to_i
    
    if !f_params[:service_life_year].blank? and !f_params[:service_life_month].blank?
      service_life_year = f_params[:service_life_year].to_i
      service_life_month = f_params[:service_life_month].to_i

      total_depreciated_month = (service_life_year*12) + service_life_month
      scrap_value = ((original_cost * 12).to_f / (total_depreciated_month+12)).round
      total_depreciated_price = original_cost - scrap_value

      depreciated_value_per_month  = (total_depreciated_price.to_f / total_depreciated_month).round

      f_params[:depreciated_value_last_month] = total_depreciated_price - (depreciated_value_per_month*(total_depreciated_month-1))
      f_params[:depreciated_value_per_month] = depreciated_value_per_month
    end
    f_params[:accumulated_depreciated_value] = 0
    f_params[:update_value_date] = DateTime.now
    @fixedasset = Fixedasset.new(f_params)

    @fixedasset.status = :in_use

    if @fixedasset.save
      redirect_to 'admin_fixedassets_path'
    else
      render :new
    end
  end

  def edit
    @fixedasset = Fixedasset.find(params[:id])
  end

  def update
    @fixedasset = Fixedasset.find(params[:id])
    f_params = fixedasset_params 
    fixed_asset_id = f_params[:fixed_asset_id]
    f_params[:ab_type] = fixed_asset_id[0]
    f_params[:year] = fixed_asset_id[1..2].to_i
    f_params[:category_id] = fixed_asset_id[3].to_i
    f_params[:category_lv2] = fixed_asset_id[4]
    f_params[:serial_no] = fixed_asset_id[5..7].to_i
    f_params[:sequence_no] = fixed_asset_id[9..10].to_i
    if @fixedasset.update(f_params)
      redirect_to admin_fixedassets_path(@fixedasset, :page => cookies[:last_fixedassets_paginated])
    else
      render :edit
    end
  end

  private

  def fixedasset_params
    params.require(:fixedasset).permit(:fixed_asset_id, 
      :voucher_no, :name, :spec, :quantity, :unit, :original_cost, :get_date, 
      :service_life_year, :service_life_month, :owned_department, :vendor_id, :note, :start_use_date,
      :is_mortgaged)
  end


end
