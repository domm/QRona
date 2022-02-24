import {beep_error}   from "@/components/beep/beep_error.base64";
import {beep_success} from "@/components/beep/beep_success.base64";
import {beep_warning} from "@/components/beep/beep_warning.base64";
import {beep_checkin_success} from "@/components/beep/beep_checkin_success.base64";
import {beep_scan_to_add_success} from "@/components/beep/beep_scan_to_add_success.base64";
import {beep_set_complete} from "@/components/beep/beep_set_complete.base64";

export function beep(type) {
  let beeper = beep_warning;
  switch(type) {
    case 'error':
      beeper = beep_error;
      break;
    case 'success':
      beeper = beep_success;
      break;
    case 'warning':
      beeper = beep_warning;
      break;
    case 'checkin_success':
      beeper = beep_checkin_success;
      break;
    case 'scan_to_add_success':
      beeper = beep_scan_to_add_success;
      break;
    case 'set_complete':
      beeper = beep_set_complete;
      break;
  }
  beeper.cloneNode().play();
}
