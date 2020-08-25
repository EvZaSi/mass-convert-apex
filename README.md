# Mass Lead Convert

The goal of this project was to reverse engineer a managed package installed on our Salesforce instance - as both a challenge and a way to save our organization some money during a very cost focused time.

The tool itself allows the end-user to convert Leads to Contacts en-masse. It functions like so: the user selects a group of Leads on a Lead list-view that they'd like to convert. They then click a Javascript On-Click button that takes them to a Visualforce Page where they specify the Account they'd like to convert the lead to (or if they'd like to create a new Account), whether they'd like to create an opportunity or a task alongside the conversion, and then ultimately convert to the Lead.

After some initial digging in Salesforce, I found that the Visualforce pages for the tool were exposed. Ah-ha! My plan of attack was built-out like so:

1. Take note of which controller methods were called by the Visualforce pages
2. Understand how the Visualforce page represented the group of selected Leads in the pageBlockTable element
3. Take note of which attributes the Visualforce page allowed the user to mutate in the representation of these Leads
4. Understand how all of the controller methods fit together upon use by the end-user

The project was a success in the end and we were able to save some money by pivoting to this home-brew soution!
