
class Racer
  include ActiveModel::Model

  attr_accessor :id, :number, :first_name, :last_name, :gender, :group, :secs
  # convenience method for access to client in console
  def self.mongo_client
   Mongoid::Clients.default
  end

  # convenience method for access to racers collection
  def self.collection
   self.mongo_client['racers']
  end

	def initialize(params={})
		#id is special primary key needed within ActiveModel and must exist to work with
		#rails scaffold. Map the property to _id
    
		@id=params[:_id].nil? ? params[:id] : params[:_id].to_s
		@number=params[:number].to_i
		@first_name=params[:first_name]
		@last_name=params[:last_name]
		@gender=params[:gender]
		@group=params[:group]
		@secs=params[:secs].to_i
	end

  def self.find id
    Rails.logger.debug {"getting zip #{id}"}
    
    if BSON::ObjectId.legal?(id)
      result=collection.find("_id"=>BSON::ObjectId(id)).first
    else
      result=collection.find(:_id=>id).first
    end  

    
                     
    #return a new instance of the racer class if found
    return result.nil? ? nil : Racer.new(result)

  end
  # implement a find that returns a collection of document as hashes. 
  # Use initialize(hash) to express individual documents as a class 
  # instance. 
  #   * prototype - query example for value equality
  #   * sort - hash expressing multi-term sort order
  #   * skip - document to start results
  #   * limit - number of documents to include
  def self.all(prototype={}, sort={}, skip=0, limit=nil)

   
    #convert to keys to symbols
    prototype=prototype.symbolize_keys.slice(:_id, :number, :first_name, :last_name, :gender, :group, :secs) if !prototype.nil?

    Rails.logger.debug {"getting all racers, prototype=#{prototype}, sort=#{sort}, skip=#{skip}, limit=#{limit}"}

    if(limit.nil?)
		  result=collection.find(prototype)
                       .sort(sort)
                       .skip(skip)
    else
    	result=collection.find(prototype)
                       .sort(sort)
                       .skip(skip)
                    	 .limit(limit)
	  end
    return result
  end

  #saves the current instance of a Racer into the database. ID is set to string version.
  def save
    result=self.class.collection.insert_one(_id:@id, number:@number, first_name:@first_name, 
                                            last_name:@last_name, group:@group, secs:@secs, gender:@gender)
    @id=result.inserted_id.to_s #save string version to id
  end

  #read in new values for instance variables and replace old with hash passed in
  def update(params)
    @number=params[:number].to_i
    @first_name=params[:first_name]
    @last_name=params[:last_name]
    @secs=params[:secs].to_i
    @gender=params[:gender]
    @group=params[:group]

    params.slice!(:number, :first_name, :last_name, :gender, :group, :secs)
    
    self.class.collection.find(:_id=>BSON::ObjectId.from_string(@id)).replace_one(params)
  end

  def persisted?
    !@id.nil?
  end

  def created_at
    nil
  end

  def updated_at
    nil
  end
  #implememts the will_paginate paginate method that accepts
  # page - number >= 1 expressing offset in pages
  # per_page - row limit within a single page
  # also take in some custom parameters like
  # sort - order criteria for document
  # (terms) - used as a prototype for selection
  # This method uses the all() method as its implementation
  # and returns instantiated Zip classes within a will_paginate
  # page
  def self.paginate(params)
    page=(params[:page] || 1).to_i
    limit=(params[:per_page] || 30).to_i
    skip=(page-1)*limit
    #sort ascending by racer number

    racers=[]
    #convert each document hash to an instance of a Racer class
    #uses class method all to filter down
    all(params, {:number=>1}, skip, limit).each do |doc|
      racers << Racer.new(doc)
    end
    total=all(params, {:number=>1}, 0, 1).count

    WillPaginate::Collection.create(page, limit, total) do |pager|
      pager.replace(racers)
    end

  end
    
  def destroy
    self.class.collection.find(number:@number).delete_one()
  end

end