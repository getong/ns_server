import {Component, ChangeDetectionStrategy} from '/ui/web_modules/@angular/core.js';
import {MnLifeCycleHooksToStream} from './mn.core.js';
import {merge} from '/ui/web_modules/rxjs.js';
import {takeUntil, map, withLatestFrom,
        first, throttleTime} from '/ui/web_modules/rxjs/operators.js';
import {MnPoolsService} from './mn.pools.service.js';
import {MnAdminService} from "./mn.admin.service.js";
import {MnHelperService} from "./mn.helper.service.js";

export {MnServicesConfigComponent};

class MnServicesConfigComponent extends MnLifeCycleHooksToStream {
  static get annotations() { return [
    new Component({
      selector: "mn-services-config",
      templateUrl: "/ui/app/mn.services.config.html",
      inputs: [
        "group",
        "initDataStream",
        "isFlagEnabled",
        "isFieldEnabled"
      ],
      changeDetection: ChangeDetectionStrategy.OnPush
    })
  ]}

  static get parameters() { return [
    MnHelperService,
    MnAdminService,
    MnPoolsService
  ]}

  constructor(mnHelperService, mnAdminService, mnPoolsService) {
    super();
    this.postPoolsDefault = mnAdminService.stream.postPoolsDefault;
    this.isEnterprise = mnPoolsService.stream.isEnterprise;
    this.quotaServices = mnPoolsService.stream.quotaServices;
    this.mnServices = mnPoolsService.stream.mnServices;
    this.getServiceName = mnHelperService.getServiceVisibleName;
    this.getServiceErrorName = mnHelperService.getServiceQuotaName;
  }

  ngOnInit() {
    if (!this.isFieldEnabled) {
      return;
    }
    this.focusFieldSubject =
      this.quotaServices.pipe(map(function (quotaServices) {
        return quotaServices.find(this.selectInitialFocus.bind(this))
      }.bind(this)))

    if (this.isFlagEnabled && this.isFieldEnabled) {
      this.total =
        merge(this.group.valueChanges, this.initDataStream)
        .pipe(withLatestFrom(this.quotaServices),
              map(this.calculateTotal.bind(this)));
    }
    if (this.isFlagEnabled) {
      this.quotaServices
        .pipe(first())
        .subscribe(function (services) {
          services.forEach(this.createToggleFieldStream.bind(this))
        }.bind(this));
    }

    this.group.valueChanges
      .pipe(throttleTime(500, undefined, {leading: true, trailing: true}),
            withLatestFrom(this.quotaServices),
            takeUntil(this.mnOnDestroy))
      .subscribe(this.validate.bind(this));

    this.initDataStream
      .subscribe((memoryQuota) => {
        this.group.get("field").patchValue(memoryQuota, {emitEvent: false})
      });
  }

  selectInitialFocus(service) {
    return this.group.value.field[service];
  }

  calculateTotal(source) {
    return source[1].reduce(this.getQuota.bind(this), 0);
  }

  validate(source) {
    this.postPoolsDefault.post([
      source[1].reduce(this.packQuotas.bind(this), {}), true]);
  }

  packQuotas(acc, name) {
    var service = this.getFlag(name);
    var keyName = (name == "kv" ? "m" : (name + "M")) + "emoryQuota";
    if (!this.isWithFlag || (service && service.value)) {
      acc[keyName] = this.getField(name).value;
    }
    return acc;
  }

  getQuota(acc, name) {
    var flag = this.getFlag(name);
    var field = this.getField(name);
    return acc + (((!flag || flag.value) && field.value) || 0);
  }

  createToggleFieldStream(serviceGroupName) {
    var group = this.getFlag(serviceGroupName);
    if (group) {
      group.valueChanges
        .pipe(takeUntil(this.mnOnDestroy))
        .subscribe(this.toggleFields(serviceGroupName).bind(this));
    }
  }

  toggleFields(name) {
    return function () {
      this.getField(name)[this.getFlag(name).value ? "enable" : "disable"]({onlySelf: true});
    }
  }

  getFlag(name) {
    return this.group.get("flag." + name);
  }

  getField(name) {
    return this.group.get("field." + name);
  }
}
