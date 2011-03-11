Feature: Import MRI Visits
  In order to track MRI data in the Panda
  As a user
  I want to be able to import visits that have occured.
  
  Background:
    Given the following user record
      | login | password  |
      | admin | secret    |
  
  Scenario: Import a Visit
    Given I am logged in as "admin" with password "secret"
    When I go to the homepage
    And I follow "import visit data"
    Then I should see "Import a new raw data directory"
    And I fill in "Directory" with "/Data/vtrak1/raw/test/fixtures/rpipe/johnson.merit220.visit1/mrt00000"
    And I press "Import!"
    Then I should see "Sucessfully imported raw data directory"
    And I should see "Email was succesfully sent"
    And I should see "RMRMAmrt00015"
    And I should see "1 visit"
