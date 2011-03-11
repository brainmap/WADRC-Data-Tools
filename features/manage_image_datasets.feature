Feature: Manage Image Datasets
  In order to track information on image datasets
  A Panda User
  Wants to manage datasets
  
  Background:
    Given the following user record
     | login | password |
  	 | admin | secret   |
    And a visit exists with rmr: "rmr01"
    And an image_dataset exists with series_description: "T1", visit: visit
  
  Scenario: View Visit with associated Image Dataset
    When I go to the visit's page
    Then I should see "rmr01"
    And I should see "T1"
    
  Scenario: View an Image Dataset
    When I go to the image_dataset's page
    Then I should see "T1"
