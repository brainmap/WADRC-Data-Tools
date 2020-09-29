/*
 Template Name: Upcube - Bootstrap 4 Admin Dashboard
 Author: Themesdesign
 Website: www.themesdesign.in
 File: Datatable js
 */

$(document).ready(function() {
    //$('#datatable').DataTable();

    //Buttons examples
    var table = $('#datatable').DataTable({
        buttons: ['copy', 'csv', 'pdf', 'colvis'],
        lengthMenu: [[25, 50, -1], [25, 50, "All"]],
        columnDefs: [{
        	targets: [0], orderData:[]
        }]
    });

    table.buttons().container()
        .appendTo('#datatable_wrapper .col-md-6:eq(0)');
} );