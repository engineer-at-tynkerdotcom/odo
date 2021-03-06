<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form"%>
<%@ page session="false" %>
    <head>
        <%@ include file="/resources/js/webjars.include" %>

        <title>API Profiles</title>
        <style type="text/css">
            .ui-jqgrid tr.jqgrow td, #jqgh_profilelist_name { /* MAKE PROFILE NAMES BIGGER */
                font-size: medium;
            }

            ul {
                list-style-type: none;
            }
        </style>
        <script type="text/javascript">

        function navigateHelp() {
            window.open("https://github.com/groupon/odo#readme","help");
        }

        //makes the specific profile active, goes to the database column
        function makeActive(profile_id){
            $.ajax({
                type: "POST",
                url: '<c:url value="/api/profile/' + profile_id + '/clients/-1"/>',
                data: "active=" + 'true',
                success: function(data) {
                    jQuery("#profilelist").trigger("reloadGrid");
                }
            });
        }

        //for now just opens up a new window. dont know if we will want more in the future
        /* THIS IS CALLED TO GO TO THE CORRECT "EDIT PROFILE" PAGE.*/
        function editProfile(profile_id){
            window.location = "edit/" + profile_id;
        }

        function navigateConfiguration() {
            window.location ='<c:url value = '/configuration' />';
        }

        var currentProfileId = -1;
        // this just sets the current profile ID so that other formatters can use it
        function idFormatter( cellvalue, options, rowObject ) {
            currentProfileId = cellvalue;
            return cellvalue;
        }

        // formatter for the name column
        function nameFormatter( cellvalue, options, rowObject ) {
            var cellContents = '<div class="ui-state-default" title="Edit Profile" onClick="editProfile(' + currentProfileId + ')">';
            cellContents += '<div><span class="ui-icon ui-icon-carat-1-e" style="float:right"></span></div>';
            cellContents += '<div>' + cellvalue + '</div></div>'
            return cellContents;
        }

        // formats the active check box
        function activeFormatter( cellvalue, options, rowObject ) {
            var checkedValue = 0;
            if (cellvalue == true) {
                checkedValue = 1;
            }

            var newCellValue = '<input id="active_' + currentProfileId + '" onChange="makeActive(' + currentProfileId + ')" type="checkbox" offval="0" value="' + checkedValue + '"';

            if (checkedValue == 1) {
                newCellValue += 'checked="checked"';
            }

            newCellValue += '>';

            return newCellValue;
        }

        // formatter for the options column
        function optionsFormatter( cellvalue, options, rowObject ) {
            return '<div class="ui-state-default ui-corner-all"><span class="ui-icon ui-icon-folder-open" title="Edit Groups"></span></div>';
        }

        $(document).ready(function () {

            $("#helpButton").tooltip();

            var profileList = jQuery("#profilelist");
            profileList
            .jqGrid({
                url : '<c:url value="/api/profile"/>',
                autowidth : false,
                sortable:true,
                sorttext:true,
                multiselect: true,
                multiboxonly: true,
                rowList : [], // disable page size dropdown
                pgbuttons : false, // disable page control like next, back button
                pgtext : null,
                cellEdit : true,
                datatype : "json",
                colNames : [ 'ID', 'Profile Name', 'Name'],
                colModel : [ {
                    name : 'id',
                    index : 'id',
                    width : 55,
                    hidden : true,
                    formatter: idFormatter
                }, {
                    // we have this hidden one so the form Add works properly
                    name : 'name',
                    index : 'name',
                    width : 55,
                    editable: true,
                    hidden : true
                }, {
                    name : 'name',
                    index : 'displayProfileName',
                    width : 400,
                    editable : false,
                    formatter: nameFormatter,
                    sortable:true
                }],
                jsonReader : {
                    page : "page",
                    total : "total",
                    records : "records",
                    root : 'profiles',
                    repeatitems : false
                },
                cellurl : '/testproxy/edit/api/server',
                rowList : [],
                pager : '#profilenavGrid',
                sortname : 'id',
                viewrecords : true,
                sortorder : "desc",
                caption : 'Profiles',
                sorttype: function(cell){
                    return profileList.jqGrid('getCell', cell,'Name');
                }
            });
            profileList.jqGrid('navGrid', '#profilenavGrid', {
                edit : false,
                add : true,
                del : true
            },
            {},
            {
                jqModal:true,
                url: '<c:url value="/api/profile"/>',
                beforeShowForm: function(form) {
                    $('#tr_name', form).show();
                },
                reloadAfterSubmit: true,
                closeAfterAdd:true,
                closeAfterEdit:true,
                width: 400
            },
            {
                url: '<c:url value="/api/profile/delete"/>',
                mtype: 'POST',
                reloadAfterSubmit:true,
                onclickSubmit: function(rp_ge, postdata) { /* CODE CHANGED TO ALLOW FOR MULTISELECTION*/
                    /* IDS GIVEN IN AS A STRING SEPARATED BY COMMAS.
                     SEPARATE INTO AN ARRAY.
                     */
                    var rowids = postdata.split(",");

                    /* FOR EVERY ROW ID TO BE DELETED,
                     GET THE CORRESPONDING PROFILE ID.
                     */
                    var params = "";
                    for( var i = 0; i < rowids.length; i++) {
                        var odoId = $(this).jqGrid('getCell', rowids[i], 'id');
                        params += "profileIdentifier=" + odoId + "&";

                    }

                    rp_ge.url = '<c:url value="/api/profile/delete"/>?' +
                            params;

                  }
            });
            profileList.jqGrid('gridResize');
        });


        function exportConfiguration() {
            downloadFile('<c:url value="/api/backup"/>');
        }

        function importConfiguration() {
            $("#configurationUploadDialog").dialog({
                title: "Upload New Configuration",
                modal: true,
                position:['top',20],
                buttons: {
                  "Submit": function() {
                    // submit form
                    $("#configurationUploadFileButton").click();
                  },
                  "Cancel": function() {
                      $("#configurationUploadDialog").dialog("close");
                  }
                }
            });
        }

        window.onload = function () {
            // Adapted from: http://blog.teamtreehouse.com/uploading-files-ajax
            document.getElementById('configurationUploadForm').onsubmit = function(event) {
                event.preventDefault();

                var file = document.getElementById('configurationUploadFile').files[0];
                var formData = new FormData();
                formData.append('fileData', file, file.name);
                var xhr = new XMLHttpRequest();
                xhr.open('POST', '<c:url value="/api/backup"/>', true);
                xhr.onload = function () {
                  if (xhr.status === 200) {
                    location.reload();
                  } else {
                    $("#statusNotificationStateDiv").removeClass("ui-state-highlight");
                    $("#statusNotificationStateDiv").addClass("ui-state-error");
                    $("#statusNotificationText").html("An error occurred while uploading configuration...");

                    // enable form buttons
                    $(":button:contains('Submit')").prop("disabled", false).removeClass("ui-state-disabled");
                    $(":button:contains('Cancel')").prop("disabled", false).removeClass("ui-state-disabled");
                  }
                };

                $("#statusNotificationText").html("Uploading configuration...");
                $("#statusNotificationStateDiv").removeClass("ui-state-error");
                $("#statusNotificationStateDiv").addClass("ui-state-highlight");
                $("#statusNotificationDiv").fadeIn();

                // disable form buttons
                $(":button:contains('Submit')").prop("disabled", true).addClass("ui-state-disabled");
                $(":button:contains('Cancel')").prop("disabled", true).addClass("ui-state-disabled");

                xhr.send(formData);
            }
        }


        </script>
    </head>

    <body>
        <!-- Hidden div for configuration file upload -->
        <div id="configurationUploadDialog" style="display:none;">
            <form id="configurationUploadForm" action="<c:url value="/api/backup"/>" method="POST">
                <input id="configurationUploadFile" type="file" name="fileData" />
                <button id="configurationUploadFileButton" type="submit" style="display: none;"></button>
            </form>

            <!-- div for status notice -->
            <div class="ui-widget" id="statusNotificationDiv" style="display: none;">
                <div class="ui-state-highlight ui-corner-all" id="statusNotificationStateDiv" style="margin-top: 10px;  margin-bottom: 10px; padding: 0 .7em;">
                    <p style="margin-top: 10px; margin-bottom:10px;"><span class="ui-icon ui-icon-info" style="float: left; margin-right: .3em;"></span>
                    <span id="statusNotificationText"/>gfdgfd</p>
                </div>
            </div>
        </div>

        <nav class="navbar navbar-default" role="navigation">
            <div class="container-fluid">
                <div class="collapse navbar-collapse">
                    <ul class="nav navbar-nav navbar-left">
                        <li class="navbar-brand">Odo</li>
                        <li class="dropdown">
                            <a href="#" class="dropdown-toggle" data-toggle="dropdown">Options <b class="caret"></b></a>
                            <ul class="dropdown-menu">
                                <li><a href="#" onclick='exportConfiguration()'>Export Configuration</a></li>
                                <li><a href="#" onclick='importConfiguration()'>Import Configuration</a></li>
                            </ul>
                        </li>
                    </ul>
                    <div class="form-group navbar-form navbar-left">
                        <button id="helpButton" class="btn btn-info" onclick="navigateHelp()"
                                target="_blank" data-toggle="tooltip" data-placement="bottom" title="Click here to read the readme.">Need Help?</button>
                    </div>
                    <ul class="nav navbar-nav navbar-right">
                        <li>
                            <p class="navbar-text">Odo Version: <c:out value = "${version}"/></p>
                        </li>
                    </ul>
                </div>
            </div>
        </nav>

        <div style="width:400px;">
            <table id="profilelist"></table>
            <div id="profilenavGrid"></div>
        </div>
    </body>
</html>