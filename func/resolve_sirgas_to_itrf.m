function itrf = resolve_sirgas_to_itrf(fr)

    fr = string(fr);

    if fr == "SIRGAS2022"
        itrf = "ITRF2014";
    elseif fr == "SIRGAS2000"
        itrf = "ITRF2000";
    else
        itrf = fr;
    end
end