//
//  giftSourceDetailViewController.m
//  Gift Tracker
//
//  Created by Tam Do on 7/12/13.
//  Copyright (c) 2013 Fair Political Practices Commission. All rights reserved.
//

#import "giftSourceDetailViewController.h"
#import "Source.h"
#import "giftEditSourceViewController.h"
#import "DAO.h"
#import "giftAppDelegate.h"

@interface giftSourceDetailViewController ()


@end

@implementation giftSourceDetailViewController

@synthesize source, name, addr1, addr2, city, state, zip, business, lobbyist, email, phone;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.dao = ( (giftAppDelegate *)[[UIApplication sharedApplication] delegate] ).dao;
    [self configureView];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

-(void)configureView {
    Source * s = self.source;
    self.name.text=s.name;
    self.addr1.text=s.addr1;
    self.addr2.text=s.addr2;
    self.city.text=s.city;
    self.state.text=s.state;
    self.zip.text=s.zip;
    self.business.text=s.business;
    self.email.text=s.email;
    self.phone.text=s.phone;
    self.lobbyist.text= (s.lobby)?@"Lobbyist":@"";
}

-(IBAction)cancelEdit:(UIStoryboardSegue *)segue {
}

- (IBAction)deleteButton:(UIButton *)sender {
    UIAlertView * doubleCheck = [[UIAlertView alloc] initWithTitle:@"Are you sure?" message:@"Delete?" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
    [doubleCheck show];
}

-(IBAction)saveEdit:(UIStoryboardSegue *)segue {
    if ([[segue identifier] isEqualToString:@"SaveEdit"]) {
        giftEditSourceViewController * editController = [segue sourceViewController];
        if (editController.source) {
            if ([self.dao updateSource:self.source newSource:editController.source]) {
                // update successfully, now update the view
                
                // both source property in two view controller are strong, dont assign nor copy it whole
                // I know it's tedious, but it's safer this way
                // idno should stay the same for self.source
                self.source.name = editController.source.name;
                self.source.addr1 = editController.source.addr1;
                self.source.addr2 = editController.source.addr2;
                self.source.city = editController.source.city;
                self.source.state = editController.source.state;
                self.source.zip = editController.source.zip;
                self.source.business = editController.source.business;
                self.source.lobby = editController.source.lobby;
                self.source.email = editController.source.email;
                self.source.phone = editController.source.phone;
                
                //nil the editController source
                editController.source = nil;
                
                //reload
                [self configureView];
            }
        }
    }
//    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"SourceDetailsToEdit"]) {
        UINavigationController * nav = [segue destinationViewController];
        giftEditSourceViewController * editController = [[nav viewControllers] objectAtIndex:0];
        editController.source = self.source;
        // again, they are strong 
    }
}

@end