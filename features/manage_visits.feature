Feature: View Visits
  In order to view visits
  As a lab member
  I want to be able to view visits
  
  Background:
    Given the following user record
      | login | password  |
      | admin | secret    |
    And a visit exists with rmr: "rmr01", date: "2009-01-01"
  
  Scenario: View a Visit
    # Given a visit exists with date: "2009-01-01", rmr: "rmr01"
    When I go to the homepage
    Then I should see "2009-01-01"
    And I follow "2009-01-01"
    Then I should be on the visit's page
    And I should see "rmr01"
    And I should see "2009-01-01"
    And I should see "January 1, 2009"

  Scenario: Edit a Visit with new enumber
    Given I am logged in as "admin" with password "secret"
    # And a visit exists with rmr: "rmr01"
    When I go to the visit's edit page
    Then I should see "Editing visit"
    And I fill in "enumber" with "enumber999"
    And I press "Edit visit"
    Then I should be on the visit's page
    And I should see "visit was successfully updated"
    And I should see "enumber999"

  
  Scenario: Edit a Visit with existing enumber
    Given I am logged in as "admin" with password "secret"
    # And a visit exists with rmr: "rmr01"
    And an enrollment exists with enumber: "enumber001"
    When I go to the visit's edit page
    Then I should see "Editing visit"
    And I fill in "enumber" with "enumber001"
    And I press "Edit visit"
    Then I should be on the visit's page
    And I should see "visit was successfully updated"  
    And I should see "enumber001"

  Scenario: Edit a Visit with a bad enumber
    Given I am logged in as "admin" with password "secret"
    When I go to the visit's edit page
    Then I should see "Editing visit"
    And I fill in "enumber" with "enumber"
    And I press "Edit visit"
    Then I should be on the visit's page
    And I should not see "visit was successfully updated"
    And I should see "Enrollment invalid"  
    
  Scenario: Create a visit
    Given I am logged in as "admin" with password "secret"
    And an enrollment exists with enumber: "enumber001"
    When I go to the new visit page
    Then I should see "New Visit"
    And I select "2011-8-18" as the date
    And I fill in "enumber" with "enumber001"
    And I fill in "initials" with "abc"
    And I press "create visit"
    Then I should see "visit was successfully created"
    And I should see "enumber001"
    And I should see "2011-08-18"
    And I should see "abc"
    
  Scenario: View Scan Procedures
    Given I am not logged in
    And a scan_procedure exists with codename: "procedure1"
    When I go to the homepage
    And I select "procedure1" from "scan_procedure_id"
    And I press "In scan procedure"
    And I should see "All visits enrolled in procedure1"
    
  Scenario Outline: Sort Visits
    Given I am not logged in
    And a visit exists with rmr: "rmr02", date: "2011-01-01"
    When I go to the homepage
    And I follow "<sort_by>"
    And I should <action> "<top>" within the 1st row
    And I should <action> "<bottom>" within the 2nd row
    When I follow "<sort_by>"
    Then I should <action> "<bottom>" within the 1st row
    And I should <action> "<top>" within the 2nd row
    
    Examples:
		 | sort_by  | action        | top         | bottom      |
		 | RMR      | see           | rmr01       | rmr02       |
		 | Date     | see the date  | 2009-01-01  | 2011-01-01  |
