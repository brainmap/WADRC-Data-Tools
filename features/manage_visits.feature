
Feature: View And Edit Participant Visits
  In order to lookup participant visits
  As a guest to the website
  I want to be able to find visits that have occured.
  
  Background:
    Given the following scan_procedure records
      | codename            |
      | johnson.procedure1  |
    And the following visit records
      | date        | scan_procedure_id | rmr   |
      | 01-01-2009  | 1                 | rmr01 |
  
  
  Scenario: Go to the Visits Index
    Given I am not logged in
    When I go to the homepage
    Then I should see "All visits"
    And I should see "rmr01"
    
  