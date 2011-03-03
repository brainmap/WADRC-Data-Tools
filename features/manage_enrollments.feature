Feature: Manage enrollments
  In order to track study enrollment
  A Panda User
  wants to manage enrollments
  
  Background:
    Given the following user record
     | login | password |
  	 | admin | secret   |
  	And the following enrollment records
     |enroll_date|enumber|
     |enroll_date 1|enumber001|
     |enroll_date 2|enumber002|
     |enroll_date 3|enumber003|
     |enroll_date 4|enumber004|
  
  Scenario: Register new enrollment
		Given I am logged in as "admin" with password "secret"
    When I am on the new enrollment page
    And I select "1/1/2011" as the date
    And I fill in "Enumber" with "enumber005"
    And I press "Create"
    Then I should see "enumber005"
    And I should see "2011-01-01"
    

  # # Can't seem to get "Destroy" Ajax working with Rails3 now?  Maybe in the future.
  # # This sucessfully deletes the 3rd enrollment, but then takes you to the 3rd
  # # record show page, which is now the 4th record.
  # Scenario: Delete enrollment
  #   When I delete the 3rd enrollment
  #   Then show me the page
  #   And I should be on the enrollments page
  #   Then I should see the following enrollments:
  #     |Enroll date|Enumber|
  #     |enroll_date 1|enumber001|
  #     |enroll_date 2|enumber002|
  #     |enroll_date 4|enumber004|
  # 
