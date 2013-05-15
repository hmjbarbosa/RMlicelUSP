clear all
addpath('../matlab');
addpath('../sc');

% windows' size
wsx=250; wsy=650; 
% displacement for next window
wdx=260; xx0=-wsx;
% start position
wdy=0;   yy0=50;

% read physics constants
constants

%% LIST OF GOOD 1-HR PERIODS
%list_overlap_select
%temp_xyzw_15km

selection_2levels_016km
%selection_2levels_015km
%selection_2levels_014km
%selection_2levels_013km
%selection_2levels_012km
%selection_2levels_011km
%selection_2levels_010km
%selection_2levels_009km
%selection_2levels_008km

nw=numel(wjdi);
maxz=2000;
debug=0;

%for w=1:nw
for w=130:170
  jdi=wjdi(w);
  jdf=wjdf(w);
  disp(['=================================================================='])
  disp([datestr(jdi)])
  disp(['=================================================================='])

  radiodir=['../../sondagens/dat/'];
  search_sonde_Manaus
%  radiofile=['../../sondagens/dat/82332_2011_07_29_00Z.dat']
  read_sonde_Manaus3
  molecular
  read_ascii_Manaus3
  if (nfile==0)
    break
  end
 
%  outfile='list_overlap_sel16km_top10km_bot6km_fix4km.mat';
  outfile='temp.mat';
  tryagain=1;
  bottomlayer=7;
  toplayer=14;
  problem=0;
  first=true;
  while (tryagain)

    P(:,1)=nansum(glue355(:,:),2);
    P(:,2)=nansum(glue387(:,:),2);
    for j = 1:2
      Pr2(:,j) = P(:,j).*altsq(:);
    end
    for j=1:nfile
      tmp(:,j)=glue355(:,j).*altsq(:);
    end
    final.maxglue(w)=max(max(glue355));
    final.maxgluer2(w)=max(max(tmp));
    clear tmp

    hascloud=0;
    tmp=diff(Pr2(200:1400,1));
    if (any(abs(tmp-mean(tmp)) > 5 * std(tmp)))
      disp(['THERE IS A CLOUD IN THE PROFILE!!!!!!!!!!!!!!!!!'])
      figure(123); clf; plot(Pr2(:,1));
      title(['w= ' num2str(w) '  time=' datestr(jdi)])
      hascloud=1;
%      break
    end

    rayleigh_fit_Manaus3

% check if molecular region is long enough
%    if any(alt(RefBinTop-RefBin) < 4000)
%      tryagain=1;
%      disp(['WARN WARN WARN ---- WARN WARN WARN'])
%      disp(['molecular region too short'])
%      % allow a 500m lower rayleight-fit for fixing the negative
%      % part in beta_raman
%      bottomlayer=bottomlayer-0.5;
%      if (bottomlayer<6)
%        break
%      else
%        continue
%      end
%    else
      tryagain=0;
%    end

    Klett_Manaus
    Raman_Manaus
    Raman_beta_Manaus
    
    if (first)
      final.beta_raman0(1:maxz,w)=beta_raman(1:maxz);
      final.beta_klett0(1:maxz,w)=beta_klett(1:maxz);
      first=false;
    end

    % find top of aerosol layer (first negative beta + 1km)
    aertop=find(beta_raman(1:maxz)<0,1) + floor(1/r_bin);
    
    % check if Raman solution is stable, i.e., if it does not
    % become negative before going positive
    for i=RefBin(1):-1:100
      if all(beta_raman(i-20:i) < 0)
        disp(['WARN WARN WARN ---- WARN WARN WARN'])
        disp(['bottom layer at: ' num2str(bottomlayer) 'km too high!!'])
        % if there is space, lower by 500m for fixing the negative
        % part in beta_raman
	if (bottomlayer-0.5 > alt(aertop)*1e-3)
	  bottomlayer=bottomlayer-0.5;
	  tryagain=1;
	else
	  disp(['PROBLEM: bottom layer already at limit! ' ])
	  problem=1;
	  tryagain=0;
	end
	if (debug>1)
	  figure(30); clf; hold on; grid on;
	  plot(beta_raman(1:RefBin(1)),alt(1:RefBin(1)),'r')
	  plot(beta_raman(i-20:i),alt(i-20:i),'b','linewidth',2)
	end
        break
      else
	tryagain=0;
      end
    end

  end
  
%  if (hascloud)
%    continue
%  end

  final.beta_raman(1:maxz,w)=beta_raman(1:maxz);
  final.beta_klett(1:maxz,w)=beta_klett(1:maxz);

  % the overlap should be calculated near the bins it has effect.
  % here 1km above the first point where beta_klett > beta_raman is
  % used.
  for i=1:RefBin(1)
    if (beta_raman(i)<beta_klett(i))
      break;
    end
  end
  n=min(i+133,RefBin(1)); % add 1km
%  n=RefBin(1);

  Ulla_Overlap
  if (mod(w,5)==0)
    title(['w= ' num2str(w) '  time=' datestr(jdi)]);
    drawnow;
  end

  final.aertop(w)=aertop;
  final.RefBin(w,:)=RefBin;
  final.RefBinTop(w,:)=RefBinTop;
  final.N(w)=n;
  final.bottomlayer(w)=bottomlayer;
  final.toplayer(w)=toplayer;
  final.over(1:maxz,w)=1;
  final.over(1:n,w)=overlap(1:n);
  final.alt(1:maxz)=alt(1:maxz);
  final.jdi(w)=jdi;
  final.jdf(w)=jdf;
  final.radio{w}=radiofile;
  final.minjdi(w)=minjdi;
  final.hascloud(w)=hascloud;
  final.bg(w,:)=bg;
  final.errbg(w,:)=errbg;
  final.problem(w)=problem;
  
  if (mod(w,5)==0)
    save(outfile,'final');
  end
end

save(outfile,'final');

%