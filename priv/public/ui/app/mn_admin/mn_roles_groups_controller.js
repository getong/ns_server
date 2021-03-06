import angular from "/ui/web_modules/angular.js";
import _ from "/ui/web_modules/lodash.js";
import uiSelect from "/ui/web_modules/ui-select.js";

import mnHelper from "/ui/app/components/mn_helper.js";
import mnPromiseHelper from "/ui/app/components/mn_promise_helper.js";
import mnPoll from "/ui/app/components/mn_poll.js";
import mnSpinner from "/ui/app/components/directives/mn_spinner.js";
import mnEqual from "/ui/app/components/directives/mn_validation/mn_equal.js";
import mnFilters from "/ui/app/components/mn_filters.js";
import mnAutocompleteOff from "/ui/app/components/directives/mn_autocomplete_off.js";
import mnFocus from "/ui/app/components/directives/mn_focus.js";

import mnUserRolesList from "/ui/app/components/directives/mn_user_roles_list_controller.js";
import mnUserRolesService from "./mn_user_roles_service.js";

import mnRolesGroupsDeleteDialogController from "./mn_roles_groups_delete_dialog_controller.js";
import mnRolesGroupsAddDialogController from "./mn_roles_groups_add_dialog_controller.js";

export default "mnRolesGroups";

angular
  .module("mnRolesGroups", [
    uiSelect,
    mnHelper,
    mnPromiseHelper,
    mnPoll,
    mnSpinner,
    mnEqual,
    mnFilters,
    mnAutocompleteOff,
    mnFocus,
    mnUserRolesService,
    mnUserRolesList,
  ])
  .controller("mnRolesGroupsController", mnRolesGroupsController)
  .controller("mnRolesGroupsDeleteDialogController", mnRolesGroupsDeleteDialogController)
  .controller("mnRolesGroupsAddDialogController", mnRolesGroupsAddDialogController);

function mnRolesGroupsController($scope, $uibModal, mnPromiseHelper, mnUserRolesService, mnPoller, mnHelper, $state, poolDefault, $timeout) {
  var vm = this;

  vm.addRolesGroup = addRolesGroup;
  vm.deleteRolesGroup = deleteRolesGroup;
  vm.editRolesGroup = editRolesGroup;

  vm.filterField = $state.params.substr;

  vm.stateParams = $state.params;

  vm.pageSize = $state.params.pageSize;
  vm.pageSizeChanged = pageSizeChanged;
  vm.sortByChanged = sortByChanged;
  vm.isOrderBy = isOrderBy;
  vm.isDesc = isDesc;

  activate();

  function isOrderBy(sortBy) {
    return sortBy === $state.params.sortBy;
  }

  function isDesc() {
    return $state.params.order === "desc";
  }

  function pageSizeChanged() {
    $state.go('.', {
      pageSize: vm.pageSize
    });
  }

  function sortByChanged(sortBy) {
    $state.go('.', {
      order: $state.params.sortBy != sortBy ? "asc" :
        $state.params.order === "asc" ? "desc" : "asc",
      sortBy: sortBy
    })
  }

  function activate() {
    $scope.$watch('rolesGroupsCtl.filterField', _.debounce(function () {
      $state.go('.', {
        substr: vm.filterField || undefined
      })
    }, 500, {leading: true}), true);

    $scope.$watchGroup(["rolesGroupsCtl.stateParams.order",
                        "rolesGroupsCtl.stateParams.sortBy",
                        "rolesGroupsCtl.stateParams.substr"], _.debounce(function () {
                          $scope.$broadcast("reloadRolesGroupsPoller");
                        }, 500, {leading: true}));

    mnHelper.initializeDetailsHashObserver(vm, 'openedRolesGroups', '.');

    mnPromiseHelper(vm, mnUserRolesService.getRoles())
      .applyToScope(function (roles) {
        mnPromiseHelper(vm, mnUserRolesService.getRolesByRole(roles))
          .applyToScope("rolesByRole");
      });

    var poller = new mnPoller($scope, function () {
      return mnUserRolesService.getRolesGroupsState($state.params);
    })
        .subscribe("state", vm)
        .setInterval(10000)
        .reloadOnScopeEvent("reloadRolesGroupsPoller")
        .cycle();
  }

  function editRolesGroup(rolesGroup) {
    $uibModal.open({
      templateUrl: 'app/mn_admin/mn_roles_groups_add_dialog.html',
      controller: 'mnRolesGroupsAddDialogController as rolesGroupsAddDialogCtl',
      resolve: {
        rolesGroup: mnHelper.wrapInFunction(rolesGroup)
      }
    });
  }
  function addRolesGroup() {
    $uibModal.open({
      templateUrl: 'app/mn_admin/mn_roles_groups_add_dialog.html',
      controller: 'mnRolesGroupsAddDialogController as rolesGroupsAddDialogCtl',
      resolve: {
        rolesGroup: mnHelper.wrapInFunction(undefined)
      }
    });
  }
  function deleteRolesGroup(rolesGroup) {
    $uibModal.open({
      templateUrl: 'app/mn_admin/mn_roles_groups_delete_dialog.html',
      controller: 'mnRolesGroupsDeleteDialogController as rolesGroupsDeleteDialogCtl',
      resolve: {
        rolesGroup: mnHelper.wrapInFunction(rolesGroup)
      }
    });
  }
}
