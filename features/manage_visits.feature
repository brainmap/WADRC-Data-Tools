Feature: View And Edit Participant Visits
  In order to lookup participant visits
  As a guest to the website
  I want to be able to find visits that have occured.
  
  Background:
    Given the following visit records
      | date                  | rmr   | compile_folder  | created_at  |
      | 01-01-2009            | rmr01 | yes             | 3 years ago |
      | 01-01-2011            | rmr02 | no              | 1 year ago  |
      | Yesterday             | rmr03 | yes             | 1 day ago   |
    And the following scan_procedure records
      | codename    |
      | procedure1  |
      | procedure2  |
    And the following user record
      | login | password  |
      | admin | secret    |
    And the following enrollment record
      | enumber |
      | enumber001 |
  
  
  Scenario: Go to the Visits Index
    Given I am not logged in
    When I go to the homepage
    Then I should see "All visits"
    And I should see "rmr01"
    And I should see "3 visits"
    
  Scenario: List Visits by Scope
    Given I am not logged in
    When I go to the homepage

    And I follow "Complete"
    Then I should see "All complete visits"
    And I should see "2 visits"
    And I should see "rmr01"
    And I should see "rmr03"
    And I should not see "rmr02"
    
    And I follow "Incomplete"
    Then I should see "All incomplete visits"
    And I should not see "rmr01"
    And I should see "rmr02"
    And I should see "1 visit"
    
    And I follow "Recent imports"
    Then I should see "All recently imported visits"
    And I should not see "rmr01"
    And I should not see "rmr02"
    And I should see "rmr03"
    And I should see "1 visit"
    
  Scenario: Search for Visits
    Given I am not logged in
    When I go to the homepage
    And I follow "Search for visits"
    Then I should be on the find visits page
    And I fill in "search_rmr_contains" with "rmr01"
    And I press "Find Visits"
    Then I should see "rmr01"
    And I should see "1 visit"
    
  Scenario: View a Visit
    Given I am not logged in
    When I go to the homepage
    Then I should see "2009-01-01"
    And I follow "2009-01-01"
    Then I should be on the visit page for "rmr01"
    And I should see "rmr01"
    And I should see "2009-01-01"
    And I should see "January 1, 2009"

  Scenario: Edit a Visit with new enumber
    Given I am logged in as "admin" with password "secret"
    When I go to the edit visit page for visit "rmr01"
    Then I should see "Editing visit"
    And I fill in "enumber" with "enumber999"
    And I press "Edit visit"
    Then I should be on the visit page for "rmr01"
    And I should see "enumber999"

  
  Scenario: Edit a Visit with existing enumber
    Given I am logged in as "admin" with password "secret"
    When I go to the edit visit page for visit "rmr01"
    Then I should see "Editing visit"
    And I fill in "enumber" with "enumber001"
    And I press "Edit visit"
    Then I should be on the visit page for "rmr01"
    And I should see "enumber001"

  Scenario: Edit a Visit with a bad enumber
    Given I am logged in as "admin" with password "secret"
    When I go to the edit visit page for visit "rmr01"
    Then I should see "Editing visit"
    And I fill in "enumber" with "enumber"
    And I press "Edit visit"
    Then I should be on the visit page for "rmr01"
    And I should see "Enrollment invalid"  
    
    
  Scenario: View Scan Procedures
    Given I am not logged in
    When I go to the homepage
    And I select "procedure1" from "scan_procedure_id"
    And I press "In scan procedure"
    And I should see "All visits enrolled in procedure1"
    
  Scenario Outline: Sort Visits
    Given I am not logged in
    When I go to the homepage
    And I follow "<sort_by>"
    And I should <action> "<top>" within the 1st row
    And I should <action> "<bottom>" within the 3rd row
    When I follow "<sort_by>"
    Then I should <action> "<bottom>" within the 1st row
    And I should <action> "<top>" within the 3rd row
    
    Examples:
		 | sort_by  | action        | top         | bottom      |
		 | RMR      | see           | rmr01       | rmr03       |
		 | Date     | see the date  | 2009-01-01  | Yesterday   |
  