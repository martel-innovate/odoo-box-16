#
# See `docs.md` for package documentation.
#
{
    stdenv, fetchFromGitHub
}:
let
  vendor = fetchFromGitHub {                                   # (1)
    owner = "martel-innovate";
    repo = "odoo-box-16";
    rev = "vendor-addons-27-jan-2025";
    sha256 = "sha256-1309f8e017eeca1f873fc73bbeebe87952bbf84c82fb46bfbeb5cc832132d93e";
  };
  hr-timesheet-overtime = fetchFromGitHub {
    owner = "martel-innovate";
    repo = "custom_hr_timesheet_overtime";
    rev = "17b3dfd6d38caab572e9f1cad5a8247481b13e53";          # (2)
    sha256 = "sha256-EI4KIiHTywUqW3HYp+nn43qaqpBxQK91WFkHGgym16A=";
  };
  timesheets-by-employee = fetchFromGitHub {
    owner = "martel-innovate";
    repo = "custom_timesheets_by_employee";
    rev = "552b17658a414c2537bbfd762cdc2cf66d4213ed";          # (2)
    sha256 = "sha256-GuRROvxTx2qxtlI2N9dA0R6pxmg17O/kN6xbDpnWl7U=";
  };
  download-attachments = fetchFromGitHub {
    owner = "martel-innovate";
    repo = "custom_timesheets_by_employee";
    rev = "aaa9ca8f42c9435babd1855335f5cf9468a247ff";          # (2)
    sha256 = "sha256-GuRROvxTx2qxtlI2N9dA0R6pxmg17O/kN6xbDpnWl7U=";
  };
  hr-expense = fetchFromGitHub {
    owner = "martel-innovate";
    repo = "custom_timesheets_by_employee";
    rev = "c9f2dd2fccb7ffa19aebe0778279c2bb6ba2c815";          # (2)
    sha256 = "sha256-GuRROvxTx2qxtlI2N9dA0R6pxmg17O/kN6xbDpnWl7U=";
  };
  custom-menu-style = fetchFromGitHub {
    owner = "martel-innovate";
    repo = "custom_timesheets_by_employee";
    rev = "417033b208025442d65306f02c4b12081af0803b";          # (2)
    sha256 = "sha256-GuRROvxTx2qxtlI2N9dA0R6pxmg17O/kN6xbDpnWl7U=";
  };
  timesheet-sheet-fullwidth = fetchFromGitHub {
    owner = "martel-innovate";
    repo = "custom_timesheets_by_employee";
    rev = "0e11e16faf30ba5e8b675a0ba2a03b282368b8fb";          # (2)
    sha256 = "sha256-GuRROvxTx2qxtlI2N9dA0R6pxmg17O/kN6xbDpnWl7U=";
  };
  custom-expense-limit = fetchFromGitHub {
    owner = "martel-innovate";
    repo = "custom_timesheets_by_employee";
    rev = "e91baa7210ec93a923698800a4c4cf8a4d381e49";          # (2)
    sha256 = "sha256-GuRROvxTx2qxtlI2N9dA0R6pxmg17O/kN6xbDpnWl7U=";
  };
in stdenv.mkDerivation rec {
    pname = "odoo-addons";
    version = "1.0.0-odoo-16.0";

    src = vendor;
    src-hr-timesheet-overtime = hr-timesheet-overtime;
    src-timesheets-by-employee = timesheets-by-employee;
    src-download-attachments = download-attachments;
    src-hr-expense = hr-expense;
    src-custom-menu-style = custom-menu-style;
    src-timesheet-sheet-fullwidth = timesheet-sheet-fullwidth;
    src-custom-expense-limit = custom-expense-limit;

    installPhase = ''
      mkdir -p $out/hr_timesheet_overtime
      cp -rv ${src-hr-timesheet-overtime}/. $out/hr_timesheet_overtime

      mkdir -p $out/timesheets_by_employee
      cp -rv ${src-timesheets-by-employee}/. $out/timesheets_by_employee

      mkdir -p $out/timesheets_by_employee
      cp -rv ${src-download-attachments}/. $out/download-attachments

      mkdir -p $out/timesheets_by_employee
      cp -rv ${src-hr-expense}/. $out/hr-expense

      mkdir -p $out/timesheets_by_employee
      cp -rv ${src-custom-menu-style}/. $out/custom-menu-style

      mkdir -p $out/timesheets_by_employee
      cp -rv ${src-timesheet-sheet-fullwidth}/. $out/timesheet-sheet-fullwidth

      mkdir -p $out/timesheets_by_employee
      cp -rv ${src-custom-expense-limit}/. $out/custom-expense-limit

      cp -rv $src/vendor/addons/* $out
    '';
}
# NOTE
# ----
# 1. Vendor addons. At the moment the sources for the various vendor
# addons installed in Martel's prod Odoo are in this repo after being
# copied over from prod. This is not the way to go, but rather a stop
# gap solution. See #2.
# 2. Release tags. Ideally we'd use release tags instead of revs. But
# at the moment hr-timesheet-overtime and timesheets-by-employee don't
# have a release process in place.
#