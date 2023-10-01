function StartPayCheck()
    CreateThread(function()
      while true do
        Wait(Config.PaycheckInterval)
        for player, xPlayer in pairs(BPT.Players) do
          local job = xPlayer.job.grade_name
          local salary = xPlayer.job.grade_salary
          if salary > 0 then
            if job == 'unemployed' then -- unemployed
              xPlayer.addAccountMoney('bank', salary, "Welfare Check")
              TriggerClientEvent('bpt:showAdvancedNotification', player, _U('bank'), _U('received_paycheck'), _U('received_help', salary),
                'CHAR_BANK_MAZE', 9)
            elseif Config.EnableSocietyPayouts then -- possibly a society
              TriggerEvent('bpt_society:getSociety', xPlayer.job.name, function(society)
                if society ~= nil then -- verified society
                  TriggerEvent('bpt_addonaccount:getSharedAccount', society.account, function(account)
                    if account.money >= salary then -- does the society money to pay its employees?
                      xPlayer.addAccountMoney('bank', salary, "Paycheck")
                      account.removeMoney(salary)
                      TriggerClientEvent('bpt:showAdvancedNotification', player, _U('bank'), _U('received_paycheck'),
                        _U('received_salary', salary), 'CHAR_BANK_MAZE', 9)
                    else
                      TriggerClientEvent('bpt:showAdvancedNotification', player, _U('bank'), '', _U('company_nomoney'), 'CHAR_BANK_MAZE', 1)
                    end
                  end)
                else -- not a society
                  xPlayer.addAccountMoney('bank', salary, "Paycheck")
                  TriggerClientEvent('bpt:showAdvancedNotification', player, _U('bank'), _U('received_paycheck'), _U('received_salary', salary),
                    'CHAR_BANK_MAZE', 9)
                end
              end)
            else -- generic job
              xPlayer.addAccountMoney('bank', salary, "Paycheck")
              TriggerClientEvent('bpt:showAdvancedNotification', player, _U('bank'), _U('received_paycheck'), _U('received_salary', salary),
                'CHAR_BANK_MAZE', 9)
            end
          end
        end
      end
    end)
end