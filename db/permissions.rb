
########################
#        PERFIS        #
########################

###############
#    ALUNO    #
###############

puts "  - Criando Permissoes do perfil aluno"

perm_alunos = PermissionsResource.create([
    # offer
    {:profile_id => 1, :resource_id => 6, :per_id => true},
    {:profile_id => 1, :resource_id => 7, :per_id => true},
    # group
    {:profile_id => 1, :resource_id => 9, :per_id => true},
    {:profile_id => 1, :resource_id => 10, :per_id => true},
    # curriculum unit
    {:profile_id => 1, :resource_id => 11, :per_id => false},
    {:profile_id => 1, :resource_id => 12, :per_id => false},
    {:profile_id => 1, :resource_id => 13, :per_id => false},
    {:profile_id => 1, :resource_id => 18, :per_id => false},
    {:profile_id => 1, :resource_id => 19, :per_id => false},
    {:profile_id => 1, :resource_id => 20, :per_id => false},
    {:profile_id => 1, :resource_id => 21, :per_id => false},
    {:profile_id => 1, :resource_id => 22, :per_id => false},
    {:profile_id => 1, :resource_id => 23, :per_id => false},
    {:profile_id => 1, :resource_id => 24, :per_id => false},

    {:profile_id => 1, :resource_id => 27, :per_id => false},
    {:profile_id => 1, :resource_id => 28, :per_id => false},
    {:profile_id => 1, :resource_id => 29, :per_id => false},
    {:profile_id => 1, :resource_id => 30, :per_id => false},
    {:profile_id => 1, :resource_id => 31, :per_id => false},
    {:profile_id => 1, :resource_id => 32, :per_id => false},
    {:profile_id => 1, :resource_id => 33, :per_id => false},
    {:profile_id => 1, :resource_id => 34, :per_id => false},

    # discussion
    {:profile_id => 1, :resource_id => 42, :per_id => false},
    {:profile_id => 1, :resource_id => 43, :per_id => false},
    {:profile_id => 1, :resource_id => 44, :per_id => false},
    {:profile_id => 1, :resource_id => 45, :per_id => false},
    {:profile_id => 1, :resource_id => 46, :per_id => false},
    {:profile_id => 1, :resource_id => 49, :per_id => false},
    {:profile_id => 1, :resource_id => 50, :per_id => false},
    {:profile_id => 1, :resource_id => 51, :per_id => false},
    {:profile_id => 1, :resource_id => 53, :per_id => false},
    # acompanhamento
    {:profile_id => 1, :resource_id => 47, :per_id => true},
    {:profile_id => 1, :resource_id => 52, :per_id => true},
    # Material de apoio
    {:profile_id => 1, :resource_id => 54, :per_id => false},
    {:profile_id => 1, :resource_id => 55, :per_id => false},
    {:profile_id => 1, :resource_id => 56, :per_id => false},
    {:profile_id => 1, :resource_id => 57, :per_id => false}
    
  ])

##############################
#      PROFESSOR TITULAR     #
##############################

puts "  - Criando Permissoes do perfil prof. titular"

perm_prof_titular = PermissionsResource.create([
    # offer
    {:profile_id => 2, :resource_id => 6, :per_id => true},
    {:profile_id => 2, :resource_id => 7, :per_id => true},
    # group
    {:profile_id => 2, :resource_id => 9, :per_id => true},
    {:profile_id => 2, :resource_id => 10, :per_id => true},
    # curriculum unit
    {:profile_id => 2, :resource_id => 11, :per_id => false},
    {:profile_id => 2, :resource_id => 12, :per_id => false},
    {:profile_id => 2, :resource_id => 13, :per_id => false},
    {:profile_id => 2, :resource_id => 18, :per_id => false},
    {:profile_id => 2, :resource_id => 19, :per_id => false},
    {:profile_id => 2, :resource_id => 20, :per_id => false},
    {:profile_id => 2, :resource_id => 21, :per_id => false},
    {:profile_id => 2, :resource_id => 22, :per_id => false},
    {:profile_id => 2, :resource_id => 23, :per_id => false},
    # portfolio
    {:profile_id => 2, :resource_id => 30, :per_id => false},
    {:profile_id => 2, :resource_id => 35, :per_id => false},
    {:profile_id => 2, :resource_id => 36, :per_id => false},
    {:profile_id => 2, :resource_id => 37, :per_id => false},
    {:profile_id => 2, :resource_id => 38, :per_id => false},
    {:profile_id => 2, :resource_id => 39, :per_id => false},
    {:profile_id => 2, :resource_id => 40, :per_id => false},
    #discussion
    {:profile_id => 2, :resource_id => 42, :per_id => false},
    {:profile_id => 2, :resource_id => 43, :per_id => false},
    {:profile_id => 2, :resource_id => 44, :per_id => false},
    {:profile_id => 2, :resource_id => 45, :per_id => false},
    {:profile_id => 2, :resource_id => 46, :per_id => false},
    {:profile_id => 2, :resource_id => 49, :per_id => false},
    {:profile_id => 2, :resource_id => 50, :per_id => false},
    {:profile_id => 2, :resource_id => 51, :per_id => false},
    {:profile_id => 2, :resource_id => 53, :per_id => false},

    # acompanhamento
    {:profile_id => 2, :resource_id => 47, :per_id => false},
    {:profile_id => 2, :resource_id => 48, :per_id => false},
    {:profile_id => 2, :resource_id => 52, :per_id => false},

    # Material de apoio
    {:profile_id => 2, :resource_id => 54, :per_id => false},
    {:profile_id => 2, :resource_id => 55, :per_id => false},
    {:profile_id => 2, :resource_id => 56, :per_id => false},
    {:profile_id => 2, :resource_id => 57, :per_id => false}
  ])

##############################
#      TUTOR A DISTANCIA     #
##############################

puts "  - Criando Permissoes do perfil tutor a dist."

perm_prof_titular = PermissionsResource.create([
    # offer
    {:profile_id => 3, :resource_id => 6, :per_id => true},
    {:profile_id => 3, :resource_id => 7, :per_id => true},
    # group
    {:profile_id => 3, :resource_id => 9, :per_id => true},
    {:profile_id => 3, :resource_id => 10, :per_id => true},
    # curriculum unit
    {:profile_id => 3, :resource_id => 11, :per_id => false},
    {:profile_id => 3, :resource_id => 12, :per_id => false},
    {:profile_id => 3, :resource_id => 13, :per_id => false},
    {:profile_id => 3, :resource_id => 18, :per_id => false},
    {:profile_id => 3, :resource_id => 19, :per_id => false},
    {:profile_id => 3, :resource_id => 20, :per_id => false},
    {:profile_id => 3, :resource_id => 21, :per_id => false},
    {:profile_id => 3, :resource_id => 22, :per_id => false},
    {:profile_id => 3, :resource_id => 23, :per_id => false},
    {:profile_id => 3, :resource_id => 24, :per_id => false},
    # portfolio
    {:profile_id => 3, :resource_id => 35, :per_id => false},
    {:profile_id => 3, :resource_id => 36, :per_id => false},
    {:profile_id => 3, :resource_id => 37, :per_id => false},
    {:profile_id => 3, :resource_id => 38, :per_id => false},
    {:profile_id => 3, :resource_id => 39, :per_id => false},
    {:profile_id => 3, :resource_id => 40, :per_id => false},

    #discussion
    {:profile_id => 3, :resource_id => 42, :per_id => false},
    {:profile_id => 3, :resource_id => 43, :per_id => false},
    {:profile_id => 3, :resource_id => 44, :per_id => false},
    {:profile_id => 3, :resource_id => 45, :per_id => false},
    {:profile_id => 3, :resource_id => 46, :per_id => false},
    {:profile_id => 3, :resource_id => 47, :per_id => false},
    {:profile_id => 3, :resource_id => 48, :per_id => false},
    {:profile_id => 3, :resource_id => 49, :per_id => false},
    {:profile_id => 3, :resource_id => 50, :per_id => false},
    {:profile_id => 3, :resource_id => 51, :per_id => false},
    {:profile_id => 3, :resource_id => 53, :per_id => false},

    # Material de apoio
    {:profile_id => 3, :resource_id => 54, :per_id => false},
    {:profile_id => 3, :resource_id => 55, :per_id => false},
    {:profile_id => 3, :resource_id => 56, :per_id => false},
    {:profile_id => 3, :resource_id => 57, :per_id => false}
    
  ])


##############################
#           EDITOR           #
##############################

puts "  - Criando Permissoes do perfil editor"

perm_editor = PermissionsResource.create([
    {:profile_id => 5, :resource_id => 63, :per_id => false},
    {:profile_id => 5, :resource_id => 64, :per_id => false},
    {:profile_id => 5, :resource_id => 65, :per_id => false},
    {:profile_id => 5, :resource_id => 66, :per_id => false}
  ])

##############################
#           BASICO           #
##############################

puts "  - Criando Permissoes do perfil basico"

perm_basico = PermissionsResource.create([
    {:profile_id => 12, :resource_id => 2, :per_id => false},
    {:profile_id => 12, :resource_id => 3, :per_id => true},
    {:profile_id => 12, :resource_id => 4, :per_id => true},
    {:profile_id => 12, :resource_id => 8, :per_id => true},
        
    {:profile_id => 12, :resource_id => 14, :per_id => false},
    {:profile_id => 12, :resource_id => 15, :per_id => false},
    {:profile_id => 12, :resource_id => 16, :per_id => false},
    {:profile_id => 12, :resource_id => 17, :per_id => false}
  ])


######## PERMISSIONS MENUS #########

puts "  - Criando Permissoes de Menu"

PermissionsMenu.create([
    {:profile_id => 1, :menu_id => 10},
    {:profile_id => 1, :menu_id => 101},
    {:profile_id => 1, :menu_id => 20},
    {:profile_id => 1, :menu_id => 201},
    {:profile_id => 1, :menu_id => 202},
    {:profile_id => 1, :menu_id => 204},
    {:profile_id => 1, :menu_id => 30},
    {:profile_id => 1, :menu_id => 301},
    {:profile_id => 1, :menu_id => 303},
    {:profile_id => 1, :menu_id => 304},
    {:profile_id => 1, :menu_id => 50},
    #{:profile_id => 1, :menu_id => 100},
    #{:profile_id => 1, :menu_id => 70},
    {:profile_id => 1, :menu_id => 302},
    {:profile_id => 1, :menu_id => 102},

    # professor titular
    {:profile_id => 2, :menu_id => 10},
    {:profile_id => 2, :menu_id => 101},
    {:profile_id => 2, :menu_id => 20},
    {:profile_id => 2, :menu_id => 201},
    {:profile_id => 2, :menu_id => 207},
    {:profile_id => 2, :menu_id => 208},
    {:profile_id => 2, :menu_id => 30},
    {:profile_id => 2, :menu_id => 301},
    {:profile_id => 2, :menu_id => 303},
    {:profile_id => 2, :menu_id => 304},
    {:profile_id => 2, :menu_id => 50},
    #{:profile_id => 2, :menu_id => 100},
    #{:profile_id => 2, :menu_id => 70},
    {:profile_id => 2, :menu_id => 302},
    {:profile_id => 2, :menu_id => 102},

    # tutor a distancia
    {:profile_id => 3, :menu_id => 10},
    {:profile_id => 3, :menu_id => 101},
    {:profile_id => 3, :menu_id => 20},
    {:profile_id => 3, :menu_id => 201},
    {:profile_id => 3, :menu_id => 202},
    {:profile_id => 3, :menu_id => 30},
    {:profile_id => 3, :menu_id => 301},
    {:profile_id => 3, :menu_id => 303},
    {:profile_id => 3, :menu_id => 304},
    {:profile_id => 3, :menu_id => 50},
    #{:profile_id => 3, :menu_id => 100},
    #{:profile_id => 3, :menu_id => 70},
    {:profile_id => 3, :menu_id => 302},
    {:profile_id => 3, :menu_id => 102},

    #editor
    {:profile_id => 5, :menu_id => 10},
    {:profile_id => 5, :menu_id => 101},
    {:profile_id => 5, :menu_id => 20},
    {:profile_id => 5, :menu_id => 201},
    {:profile_id => 5, :menu_id => 202},
    {:profile_id => 5, :menu_id => 30},
    {:profile_id => 5, :menu_id => 301},
    {:profile_id => 5, :menu_id => 303},
    {:profile_id => 5, :menu_id => 304},
    {:profile_id => 5, :menu_id => 50},
    #{:profile_id => 5, :menu_id => 100},
    #{:profile_id => 5, :menu_id => 70},
    {:profile_id => 5, :menu_id => 302},
    {:profile_id => 5, :menu_id => 102},
    {:profile_id => 5, :menu_id => 120},
    
    #basico
    {:profile_id => 12, :menu_id => 100}

  ])