class ItemsController < ApplicationController
  layout 'modal', except: :index

  before_action :set_person_and_list
  before_action :set_item, except: [:index, :new, :create]
  before_action :set_create_url, only: [:new, :create, :purchase, :unpurchase, :destroy]
  before_action :set_edit_url, only: [:edit, :update]


  def index
    @items = @list.items
    set_page_subtitle current_year
    if @list.person == current_person
      set_page_title 'Your List'
      @items = @items.where(creator: @list.person).without_deleted
      render action: 'index_owner'
    else
      set_page_title "#{@list.person.first_name}'s List"
    end
  end

  def new
    set_page_title 'Add Item'
    @item = @list.items.build
  end

  def edit
    set_page_title 'Edit Item'
  end

  def create
    @item = @list.items.build(item_params)
    if @item.save
      redirect_to @submit_url
    else
      render action: 'new'
    end
  end

  def update
    if @item.update(item_params)
      redirect_to list_items_path(@list)
    else
      render action: 'edit'
    end
  end

  def destroy
    if @item.destroy_or_hide
      redirect_to @submit_url
    else
      render action: 'edit'
    end
  end

  def purchase
    unless @item.purchaser
      if @item.update purchaser: current_person
        redirect_to @submit_url
      else
        render action: 'edit'
      end
    end
  end

  def unpurchase
    if @item.purchased_by?(current_person)
      if @item.update purchaser: nil
        redirect_to @submit_url
      else
        render action: 'edit'
      end
    end
  end

  private

  def set_person_and_list
    if params[:group_id]
      @group = current_person.groups.find(params[:group_id])
      @list = List.joins(:groups).where(id: params[:list_id], groups: {id: @group.id}).first
      if @list.year != current_year
        current_list = List.joins(:groups).where(person_id: @list.person_id, groups: {id: @group.id}).for_year(current_year).first
        if current_list
          redirect_to group_list_items_path(params[:group_id], current_list.id)
        else
          redirect_to group_path(params[:group_id])
        end
        return
      end
      @person = @list.person
    else
      @list = current_person.lists.find(params[:list_id])
      if @list.year != current_year
        current_list = current_person.list_for_year(current_year)
        if current_list
          redirect_to list_items_path(current_list.id)
        else
          redirect_to root_path
        end
        return
      end
      @person = current_person
    end
  end

  def set_item
    @item = @list.items.find(params[:id] || params[:item_id])
  end

  def set_create_url
    @submit_url = if @group
      group_list_items_path(@group, @list)
    else
      list_items_path(@list)
    end
  end

  def set_edit_url
    @submit_url = if @group
      group_list_item_path(@group, @list)
    else
      list_item_path(@list, @item)
    end
  end

  def item_params
    params.require(:item).permit(:name, :price, :url, :description).merge(creator: current_person)
  end
end
