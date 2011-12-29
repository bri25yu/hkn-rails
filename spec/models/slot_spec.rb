require 'spec_helper'

describe Slot, "when created with blank parameters" do
  before(:each) do
    @slot = Slot.create
  end

  it "should require hour" do
    @slot.should_not be_valid
    @slot.errors[:hour].should include("can't be blank")
  end

  it "should require wday (numeric day of week)" do
    @slot.should_not be_valid
    @slot.errors[:wday].should include("can't be blank")
  end

  it "should require a room" do
    @slot.should_not be_valid
    @slot.errors[:room].should include("can't be blank")
  end
end

describe Slot do
  before(:each) do
    @good_opts = {
      :hour => 11,
      :wday => 1,
      :room => 1,
    }
    @good_tutor_opts = {
      :person => mock_model(Person),
      #:availabilities => [mock_model(Availability)],
      :languages => "C"
    }
    Slot.destroy_all
  end

  it "should accept valid parameters" do
    slot = Slot.create(@good_opts)
    slot.should be_valid
  end

  it "should require a valid room" do
    slot = Slot.create(@good_opts.merge(:room => 3))
    slot.should_not be_valid
    slot.errors[:room].should include(Slot::ROOM_ERROR)
  end

  it "should require an hour during tutoring hours" do
    Property.stub(:tutoring_start) { 12 }
    Property.stub(:tutoring_end) { 14 }
    slot = Slot.create @good_opts.merge(:hour => 15)
    slot.should_not be_valid
    slot.errors[:hour].should include(Slot::HOUR_RANGE_ERROR)
  end

  it "should require a wday on a weekday" do
    slot = Slot.create @good_opts.merge(:wday => 0)
    slot.should_not be_valid
    slot.errors[:wday].should include("is not included in the list")
  end

  it "should require slots to be unique" do
    slot0 = Slot.create @good_opts
    slot1 = Slot.create @good_opts
    slot1.should_not be_valid
    slot1.errors[:hour].should include("has already been taken")
  end

  it "should not allow a tutor to be assigned to another office at the same time" do
    cory = Slot.create @good_opts.merge(:room => 0)
    soda = Slot.create @good_opts.merge(:room => 1)
    tutor = Tutor.new(:person_id => 0)
    tutor.save!(:validate => false)
    cory.tutors << tutor
    expect{soda.tutors << tutor}.to raise_error
    tutor.delete
  end
end

describe Slot, 'utility methods' do
  before(:all) do
    @good_opts = {
      :hour => 11,
      :wday => 1,
      :room => 1,
    }
    Slot.destroy_all
    @slot = Slot.new @good_opts
  end

  it 'should have to_s' do
    @slot.to_s
  end

  it 'should have inspect' do
    @slot.inspect
  end

  it 'should have room_name' do
    soda = Slot.new @good_opts.merge(:room => Slot::Room::Soda)
    soda.room_name.should == "Soda"
    cory = Slot.new @good_opts.merge(:room => Slot::Room::Cory)
    cory.room_name.should == "Cory"
  end

  it 'should have adjacent_to' do
    @slot.to_s
    slot_adj = Slot.new @good_opts.merge(:hour => 12)
    @slot.adjacent_to(slot_adj).should be_true
    slot_adj.adjacent_to(@slot).should be_true

    slot_not_adj = Slot.new @good_opts.merge(:hour => 1)
    @slot.adjacent_to(slot_not_adj).should_not be_true
    slot_not_adj.adjacent_to(@slot).should_not be_true
  end

  it 'should have availabilities' do
    Availability.destroy_all
    avail = Availability.new(:hour => 12, :wday => 1, :semester => 20113)
    avail.save(:validate => false)
    slot = Slot.new @good_opts.merge(:hour => 12, :wday => 1)
    slot.availabilities.include?(avail).should be_true
    avail.delete
  end
end
