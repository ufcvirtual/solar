puts "- Environment: #{Rails.env} - Executando fixtures"
Rake::Task['db:fixtures:load'].invoke

allocations = Allocation.create([
  {:user_id => 1, :allocation_tag_id => 1, :profile_id => 1, :status => 1},
  {:user_id => 1, :allocation_tag_id => 2, :profile_id => 1, :status => 1},
  {:user_id => 1, :allocation_tag_id => 3, :profile_id => 1, :status => 1},
  {:user_id => 1, :allocation_tag_id => 8, :profile_id => 1, :status => 0},
  {:user_id => 1, :allocation_tag_id => 9, :profile_id => 1, :status => 1},

  {:user_id => 6, :allocation_tag_id => 4, :profile_id => 2, :status => 1},
  {:user_id => 6, :allocation_tag_id => 5, :profile_id => 2, :status => 1},
  {:user_id => 6, :allocation_tag_id => 6, :profile_id => 2, :status => 1},
  {:user_id => 6, :profile_id => 12, :status => 1},

  {:user_id => 7, :allocation_tag_id => 1, :profile_id => 1, :status => 1},
  {:user_id => 7, :allocation_tag_id => 2, :profile_id => 1, :status => 1},
  {:user_id => 7, :allocation_tag_id => 3, :profile_id => 1, :status => 1},
  {:user_id => 7, :profile_id => 12, :status => 1},

  {:user_id => 8, :allocation_tag_id => 1, :profile_id => 1, :status => 1},
  {:user_id => 8, :allocation_tag_id => 2, :profile_id => 1, :status => 1},
  {:user_id => 8, :allocation_tag_id => 3, :profile_id => 1, :status => 1},
  {:user_id => 8, :profile_id => 12, :status => 1},

  {:user_id => 9, :allocation_tag_id => 1, :profile_id => 1, :status => 1},
  {:user_id => 9, :allocation_tag_id => 2, :profile_id => 1, :status => 1},
  {:user_id => 9, :allocation_tag_id => 3, :profile_id => 1, :status => 1},
  {:user_id => 9, :profile_id => 12, :status => 1},

  {:user_id => 11, :allocation_tag_id => 2, :profile_id => 3, :status => 1},
  {:user_id => 11, :allocation_tag_id => 3, :profile_id => 3, :status => 1},
  {:user_id => 11, :profile_id => 12, :status => 1},

  {:user_id => 10, :allocation_tag_id => 2, :profile_id => 4, :status => 1},
  {:user_id => 10, :allocation_tag_id => 3, :profile_id => 4, :status => 1},
  {:user_id => 10, :profile_id => 12, :status => 1},

  {:user_id => 12, :allocation_tag_id => 8, :profile_id => 5, :status => 1},
  {:user_id => 12, :allocation_tag_id => 7, :profile_id => 5, :status => 1}
])
