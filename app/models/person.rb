class Person < ActiveRecord::Base
  enum gender: [ :male, :female ]

  belongs_to :user, inverse_of: :person
  has_one :addresses, inverse_of: :person
  has_many :group_memberships, inverse_of: :person
  has_many :groups, through: :group_memberships
  has_many :guardianships, inverse_of: :person
  has_many :guardians, through: :guardianship
  has_many :created_items, class_name: 'Item', foreign_key: :creator_id, inverse_of: :creator
  has_many :purchases, class_name: 'Item', foreign_key: :purchaser_id, inverse_of: :purchaser
  has_many :lists, inverse_of: :person
  has_many :invitations, :foreign_key => 'recipient_id', inverse_of: :recipient
  has_many :sent_invitations, :class_name => "Invitation", :foreign_key => 'sender_id', inverse_of: :sender

  validates_presence_of :first_name, :last_name, :gender

  after_create :make_initial_list

  scope :by_name, -> { order(:first_name) }
  scope :without, ->(people) { where.not(id: Array(people).flatten.compact) }

  def name
    "#{first_name} #{last_name}"
  end

  def initials
    "#{first_name[0]}#{last_name[0]}"
  end

  def current_purchases_for person_or_group
    case person_or_group
    when Person
      person_or_group.lists.current.first.items.purchased_by(self)
    when Group
      list_ids = List.current.joins(:person).where(people: {id: person_or_group.people.pluck(:id)}).pluck(:id)
      Item.purchased_by(self).joins(:list).where(lists: {id: list_ids })
    end
  end

  private
  def make_initial_list
    lists.create
  end
end
