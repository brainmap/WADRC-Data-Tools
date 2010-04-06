@wip
Feature: Help Documentation
  In order get some help using the Data Panda
  As a member of the general public
  I want an easily accessible help page.

Scenario: Go to the Help Page
  Given I am on the homepage
  When I follow "Help"
  Then I should be on the help page.