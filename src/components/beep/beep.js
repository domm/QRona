import {beep_error}   from "@/components/beep/beep_error.base64";
import {beep_default} from "@/components/beep/beep_default.base64";
import {beep_test} from "@/components/beep/beep_test.base64";
import {beep_recovered} from "@/components/beep/beep_recovered.base64";
import {beep_vaccination} from "@/components/beep/beep_vaccination.base64";

export function beep(type) {
  let beeper = beep_default;
  switch(type) {
    case 'error':
      beeper = beep_error;
      break;
    case 'Test':
      beeper = beep_test;
      break;
    case 'Vaccination':
      beeper = beep_vaccination;
      break;
    case 'Recovered':
      beeper = beep_recovered;
      break;
  }
  beeper.cloneNode().play();
}
