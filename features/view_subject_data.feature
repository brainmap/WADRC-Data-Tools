Feature: View Subject Data
  In order to look at available subject data in the Panda
  An interested user
  wants to see what data is available in Participants, Scan Procedures, Analyses and Image Searches
  
  Scenario: View Participants
    Given the following participant records
      | access_id | gender  | wrapnum |
      | 0         | 1       | L001    |
      | 1         | 2       | M001    |
      | 2         | 999     |         |
    When I am on the participants page
    Then I should see "M" 
    And I should see "F"
    And I should see "unknown"
    And I should see "L001" 
    And I should see "M001"

  Scenario: View Scan Procedures
    Given the following scan_procedure records
      | codename  | description       |
      | proc1     | First procedure   |
      | proc2     | Second procedure  |
      | proc3     | Third procedure   |
    When I am on the scan_procedures page
    Then I should see "proc1"
    And I should see "proc2"
    And I should see "proc3"