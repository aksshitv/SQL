/* Intermediate table for NFL interim rank */

WITH CTE_interim AS 
(SELECT BPlayerID,
		PlayerID,
		DraftRound,
		DraftRank,
		Draftnumber,
		OrderWithinRank,
		OrderWithinRank_new,
		COUNT(Draftnumber) OVER(PARTITION BY DraftRound) AS count_DraftNumber,
		MIN(Draftnumber) OVER(PARTITION BY DraftRound) AS min_DraftNumber,
		MAX(OrderWithinRank) OVER(PARTITION BY DraftRank) AS max_DraftRank,
		MAX(OrderWithinRank_new) OVER(PARTITION BY DraftRound) AS max_DraftRanknew,
		MAX(OrderWithinRank_new) OVER(PARTITION BY CASE WHEN DraftRound =5 or DraftRound = 6 THEN '5 and 6' ELSE 'Others' END) AS max_DraftRanknew_5_6, 
		CASE WHEN DraftRank = '1A' THEN 8 
			 WHEN DraftRank = '1B' THEN 7.5
			 WHEN DraftRank = '1C' THEN 7.25
			 WHEN DraftRound = 2 THEN 6.9
			 WHEN DraftRound = 3 THEN 6.4
			 WHEN DraftRound = 4 THEN 5.9
			 -- DraftRound 5 and 6 have same upper and lower limits
			 WHEN DraftRound = 5 THEN 5.4
			 WHEN DraftRound = 6 THEN 5.4
			 WHEN DraftRound = 7 THEN 5.1
			 WHEN DraftRank = 'F1' THEN 4.9
		END AS UpperLimit,
		CASE WHEN DraftRank = '1A' THEN 7.51 
			 WHEN DraftRank = '1B' THEN 7.26
			 WHEN DraftRank = '1C' THEN 7
			 WHEN DraftRound = 2 THEN 6.5
			 WHEN DraftRound = 3 THEN 6
			 WHEN DraftRound = 4 THEN 5.5
			 -- DraftRound 5 and 6 have same upper and lower limits
			 WHEN DraftRound = 5 THEN 5.2
			 WHEN DraftRound = 6 THEN 5.2
			 WHEN DraftRound = 7 THEN 5
			 WHEN DraftRank = 'F1' THEN 4.5
		END AS LowerLimit
	FROM dbo.NFLDraft
)
SELECT PlayerID,
	   BPlayerID,
	   DraftRound,
	   Draftnumber,
	   DraftRank,
	   OrderWithinRank,
	   OrderWithinRank_new,
	   -- for 1A, 1B, 1C and F1, 
	  ROUND(CASE WHEN DraftRank IN ('1A', '1B', '1C', 'F1') THEN UpperLimit -(( OrderWithinRank-1)* ( UpperLimit - LowerLimit)/(max_DraftRank-1)) 
	   -- for Draft Round 5 and 6
	   WHEN DraftRound IN (5,6) THEN 5.4 -(( OrderWithinRank_new-1)* ( 5.4 - 5.2)/(max_DraftRanknew_5_6-1)) 
	   ELSE  UpperLimit -(( OrderWithinRank_new-1)* ( UpperLimit - LowerLimit)/(max_DraftRanknew-1)) 
	   END, 4) AS NFLRank
INTO #signingOrder
FROM CTE_interim
ORDER BY DraftRank ASC, OrderWithinRank ASC



/* Intermediate table for BengalSummary table */
select
	BPlayerId,
	ReportYear,
	PlayerId,
	ClassYear,
	NflDraftYear,
	LastName,
	FootballName,
	ColPosition,
	ProPos,
	--Calculates the age at the time player is selected for Drafting
	ROUND(NflDraftYear - year(DOB),0) AS Age,
	--If Marital status id not present, they are assumed to be single
	coalesce(MaritalStatus,'S') as MaritalStatus,
	--If there is no information on number of kids, it is assumed to be zero
	coalesce(NumberOfKids,0) as NumberOfKids, 
	Height,
	Weight,
	Arm,
	Hand,
	Wingspan,
	Bench,
	VerticalJump,
	BroadJump,
	Speed1,
	ShortShuttle,
	ThreeCone,
	--Percentage of correct answers from attempted questions is calculated
	(cast(coalesce(TestCorrect,TestCorrect2) as float)/nullif(coalesce(TestAtt,TestAtt2),0)) * 100 as TestPercent,
	--Flag that denotes the participation in All star games
	case when AllStarG1 is not null then 1 else 0 end as AllStarG1,
	--Flag that denotes the participation in Combine
	coalesce(Combine,0) as Combine,
	BengalRank,
	
	CASE WHEN [BengalRank] = '1A' THEN 7.75
		 WHEN [BengalRank] = '1B' THEN 7.375
		 WHEN [BengalRank] = '1C' THEN 7.125
		 WHEN [BengalRank] = '2A' THEN 6.8
		 WHEN [BengalRank] = '2B' THEN 6.7
		 WHEN [BengalRank] = '2C' THEN 6.6
		 WHEN [BengalRank] = '3A' THEN 6.3
		 WHEN [BengalRank] = '3B' THEN 6.2
		 WHEN [BengalRank] = '3C' THEN 6.1
		 WHEN [BengalRank] = '4A' THEN 5.8
		 WHEN [BengalRank] = '4B' THEN 5.7
		 WHEN [BengalRank] = '4C' THEN 5.6
		 WHEN [BengalRank] = '5A' THEN 5.4
		 WHEN [BengalRank] = '5B' THEN 5.37
		 WHEN [BengalRank] = '5C' THEN 5.3
		 WHEN [BengalRank] = '6A' THEN 5.27
		 WHEN [BengalRank] = '6B' THEN 5.25
		 WHEN [BengalRank] = '6C' THEN 5.2
		 WHEN [BengalRank] = '7A' THEN 5.07
		 WHEN [BengalRank] = '7B' THEN 5.05
		 WHEN [BengalRank] = '7C' THEN 5.02
		 WHEN [BengalRank] = 'F1' THEN 4.7
		 WHEN [BengalRank] = 'F2' THEN 4.2
		 WHEN [BengalRank] = 'NA' THEN 2.5
		 WHEN [BengalRank] = 'RJ' THEN 1
		 WHEN [BengalRank] is null THEN 4.7 --Assigning BengalRankNum = 4.7 for all NULLs
		 ELSE NULL
	END AS BengalRankNum,
	CharacterGrade,
	MedGradeValue
INTO #BengalSummary
FROM dbo.BengalSummaryData;



/* Intermediate table for Bengal Reports table */

SELECT BplayerId,
	   AVG(COALESCE(FinalGrade,InitialGrade)) AS AvgGrade,
	   AVG(CASE WHEN Role = 'Scout' THEN COALESCE(FinalGrade,InitialGrade) END) AS AvgScoutGrade,
	   AVG(CASE WHEN Role = 'Coach' THEN COALESCE(FinalGrade,InitialGrade) END) AS AvgCoachGrade,
	   MIN(COALESCE(FinalGrade,InitialGrade)) AS MinGrade,
	   MIN(CASE WHEN Role = 'Scout' THEN COALESCE(FinalGrade,InitialGrade) END) AS MinScoutGrade,
	   MIN(CASE WHEN Role = 'Coach' THEN COALESCE(FinalGrade,InitialGrade) END) AS MinCoachGrade,
	   MAX(COALESCE(FinalGrade,InitialGrade)) AS MaxGrade,
	   MAX(CASE WHEN Role = 'Scout' THEN COALESCE(FinalGrade,InitialGrade) END) AS MaxScoutGrade,
	   AVG(CASE WHEN Role = 'Coach' THEN COALESCE(FinalGrade,InitialGrade) END) AS MaxCoachGrade,
	   MAX( CASE WHEN ProjectedRD = '1A' THEN 7.75
		 WHEN ProjectedRD = '1B' THEN 7.375
		 WHEN ProjectedRD = '1C' THEN 7.125
		 WHEN ProjectedRD = '2A' THEN 6.8
		 WHEN ProjectedRD = '2B' THEN 6.7
		 WHEN ProjectedRD = '2C' THEN 6.6
		 WHEN ProjectedRD = '3A' THEN 6.3
		 WHEN ProjectedRD = '3B' THEN 6.2
		 WHEN ProjectedRD = '3C' THEN 6.1
		 WHEN ProjectedRD = '4A' THEN 5.8
		 WHEN ProjectedRD = '4B' THEN 5.7
		 WHEN ProjectedRD = '4C' THEN 5.6
		 WHEN ProjectedRD = '5A' THEN 5.4
		 WHEN ProjectedRD = '5B' THEN 5.37
		 WHEN ProjectedRD = '5C' THEN 5.3
		 WHEN ProjectedRD = '6A' THEN 5.27
		 WHEN ProjectedRD = '6B' THEN 5.25
		 WHEN ProjectedRD = '6C' THEN 5.2
		 WHEN ProjectedRD = '7A' THEN 5.07
		 WHEN ProjectedRD = '7B' THEN 5.05
		 WHEN ProjectedRD = '7C' THEN 5.02
		 WHEN ProjectedRD = 'F1' THEN 4.7
		 WHEN ProjectedRD = 'F2' THEN 4.2
		 WHEN ProjectedRD = 'NA' THEN 2.5
		 WHEN ProjectedRD = 'RJ' THEN 1
		 ELSE NULL
	END) AS ProjectedRD
INTO #BengalReports
FROM dbo.BengalReports
GROUP BY BPlayerId


/* Intermediate table for NFS reports */ 

SELECT BPlayerId,
	NFS_Grade,
	COALESCE(Captain,0) AS Captain,
	PERSONALCHARACTER,
	STABILITY,
	FOOTBALLCHARACTER,
	ATHLETICABILITY,
	COMPETITIVE,
	MENTALALERTNESS,
	STRENGTH,
	EXPLOSION,
	CASE WHEN BODYTYPE = 'D' THEN 4
	WHEN BODYTYPE = 'C' THEN 3
	WHEN BODYTYPE = 'B' THEN 2
	WHEN BODYTYPE = 'A' THEN 1
	ELSE null end as BODYTYPE,
	WEIGHTPOTENTIAL,
	GRADE1,
	GRADE2,
	GRADE3,
	GRADE4,
	GRADE5,
	GRADE6,
	GRADE7,
	GRADE8,
	GRADE9
INTO #NFSReports
FROM dbo.NFSReports WHERE ReportCode = 'F'

/* Intermediate table for College Playing History  */

SELECT i.BPlayerID,
	   i.Total_Games_Played,
	   i.Total_Games_Missed,
	   i.Total_Games_Started,
	   i.Number_of_Unique_Teams,
	   i.Number_of_Unique_Conf,
	   i.Number_of_Seasons,
	   j.ConferenceBig10,
	   j.ConferenceBig12,
	   j.ConferenceSEC,
	   j.ConferenceACC,
	   j.ConferencePAC12,
	   j.Power5,
	   k.Last_Games_Missed,
	   k.Last_Games_Played,
	   k.Last_Games_Started
INTO #CollegePlayingHistory
FROM
(SELECT     BPlayerID,
			SUM(GamesPlayed) as Total_Games_Played,
			SUM(GamesMissed) as Total_Games_Missed,
			sum(GamesStarted) as Total_Games_Started,
			count(distinct School) as Number_of_Unique_Teams,
			count(distinct Conference) as Number_of_Unique_Conf,
			count(distinct Season) as Number_of_Seasons
			from dbo.CollegePlayingHistory
			group by BPlayerID ) i 
/* Creates flag for each conference*/
LEFT JOIN 
(SELECT BplayerId,
		MAX(ConferenceBig10) AS ConferenceBig10,
		MAX(ConferenceBig12) AS ConferenceBig12,
		MAX(ConferenceSEC) AS ConferenceSEC,
		MAX(ConferenceACC) AS ConferenceACC,
		MAX(ConferencePAC12) AS ConferencePAC12,
		MAX(Power5) AS Power5
FROM
(SELECT 	BplayerId,
		case when Conference = 'BIG TEN CONFERENCE' then 1 else 0 end as ConferenceBig10,
		case when Conference = 'BIG 12 CONFERENCE' then 1 else 0 end as ConferenceBig12,
		case when Conference = 'SOUTHEASTERN CONFERENCE' then 1 else 0 end as ConferenceSEC,
		case when Conference = 'ATLANTIC COAST CONFERENCE' then 1 else 0 end as ConferenceACC,
		case when Conference = 'PACIFIC-12 CONFERENCE' then 1 else 0 end as ConferencePAC12,
		case when Conference in ('BIG TEN CONFERENCE','BIG 12 CONFERENCE','SOUTHEASTERN CONFERENCE','ATLANTIC COAST CONFERENCE','PACIFIC-12 CONFERENCE') then 1 else 0 end as Power5
FROM dbo.CollegePlayingHistory) AS a
GROUP BY BPlayerId) j ON i.BplayerId = j.BPlayerId
LEFT JOIN
/* The number of games Played, started and missed in the last season */
(SELECT 		x.BPlayerID,
				x.Season,
				x.GamesMissed as Last_Games_Missed,
				x.GamesPlayed as Last_Games_Played,
				x.GamesStarted as Last_Games_Started	
FROM dbo.CollegePlayingHistory x
INNER JOIN ( SELECT BPlayerID, MAX(season) as max_season 
			 FROM dbo.CollegePlayingHistory  
			 GROUP BY BPlayerId ) y
ON x.BplayerId = y.BplayerId AND x.season = y.max_season) AS k
ON i.BPlayerId = k.BPlayerId





/* Intermediate table for Injuries */


SELECT  a.BplayerId,
		COUNT(distinct a.Date) AS NumberOfInjuries,
		COALESCE(sum(b.GamesMissed),0) GamesMissedToInjury
INTO #CollegeInjuries
FROM dbo.CollegeInjuries AS a
LEFT JOIN dbo.CollegePlayingHistory b 
on a.BPlayerID=b.BPlayerID 
AND year(a.Date) = b.Season
GROUP BY a.BplayerId



/* Intermediate table for NFL Performance */

SELECT  m.playerid, 
		m.FinalRating,
		m.position,
		m.EntryYear,
		m.Season,
		m.[Z-Score] as ZScore,
		m.Median,
		m.Adj_Z,
		m.Grade,
		m.MomentumInd,
		n.BplayerId
INTO #NFLPerformance
FROM dbo.NFLPerformance  m 
Right JOIN dbo.NFLDraft n ON m.PlayerId = n.Playerid



--drop table dbo.#NFLPerformance

/* Final SQL table for Data */

select  perf.playerid,
	    coalesce(perf.FinalRating,0) as FinalRating,
		4.7 + (7.75 - 4.7) * coalesce(perf.FinalRating,0) as ScaledFinalRating,
		perf.position,
		perf.EntryYear,
		perf.Season,
		perf.ZScore,
		perf.Median,
		perf.Adj_Z,
		perf.Grade,
		perf.MomentumInd,
		signOrder.BPlayerID,
	    signOrder.NFLRank,
		summary.ReportYear,
		summary.PlayerId,
		summary.ClassYear,
		summary.NflDraftYear,
		summary.LastName,
		summary.FootballName,
		summary.ColPosition,
		summary.ProPos,
		summary.Age,
		summary.MaritalStatus,
		summary.NumberOfKids, 
		summary.Height,
		summary.Weight,
		summary.Arm,
		summary.Hand,
		summary.Wingspan,
		summary.Bench,
		summary.VerticalJump,
		summary.BroadJump,
		summary.Speed1,
		summary.ShortShuttle,
		summary.ThreeCone,
		summary.TestPercent,
		summary.AllStarG1,
		summary.Combine,
		summary.BengalRank,
		summary.BengalRankNum,
		summary.CharacterGrade,
		summary.MedGradeValue,
		report.ProjectedRD,
		report.AvgScoutGrade,
		report.MinScoutGrade,
		report.MaxScoutGrade,
		report.AvgCoachGrade,
		report.MinCoachGrade,
		report.MaxCoachGrade,
		report.AvgGrade,
		report.MinGrade,
		report.MaxGrade,
		nfs.NFS_Grade,
		coalesce(nfs.Captain,0) as Captain,
		nfs.PERSONALCHARACTER,
		nfs.STABILITY,
		nfs.FOOTBALLCHARACTER,
		nfs.ATHLETICABILITY,
		nfs.COMPETITIVE,
		nfs.MENTALALERTNESS,
		nfs.STRENGTH,
		nfs.EXPLOSION,
		nfs.BODYTYPE,
		nfs.WEIGHTPOTENTIAL,
		nfs.GRADE1,
		nfs.GRADE2,
		nfs.GRADE3,
		nfs.GRADE4,
		nfs.GRADE5,
		nfs.GRADE6,
		nfs.GRADE7,
		nfs.GRADE8,
		nfs.GRADE9,
		history.Number_of_Unique_Teams,
		history.Number_of_Unique_Conf,
		history.Number_of_Seasons,
		history.Total_Games_Played,
		history.Total_Games_Missed,
		history.Total_Games_Started,
		history.Last_Games_Missed,
		history.Last_Games_Played,
		history.Last_Games_Started,
		coalesce(history.ConferenceBig10, 0) as ConferenceBig10,
		coalesce(history.ConferenceBig12, 0) as ConferenceBig12,
		coalesce(history.ConferenceSEC, 0) as ConferenceSEC,
		coalesce(history.ConferenceACC, 0) as ConferenceACC,
		coalesce(history.ConferencePAC12, 0) as ConferencePAC12,
		coalesce(history.Power5,0) as Power5,
		COALESCE(injury.GamesMissedToInjury,0) AS GamesMissedToInjury,
		COALESCE(injury.NumberOfInjuries,0) AS NumberOfInjuries,
		CASE WHEN injury.NumberOfInjuries IS NULL THEN 0 ELSE 1 END AS InjuryIndicator
FROM #NFLPerformance AS perf 
LEFT JOIN #signingOrder AS signOrder ON perf.BPlayerId = signOrder.BPlayerId
LEFT JOIN #BengalSummary AS summary ON signOrder.BPlayerId = summary.BPlayerId
LEFT JOIN #BengalReports AS report ON signOrder.BPlayerId = report.BPlayerId
LEFT JOIN #NFSReports AS nfs ON signOrder.BPlayerId = nfs.BPlayerId
LEFT JOIN #CollegePlayingHistory AS history ON signOrder.BPlayerId = history.BPlayerId
LEFT JOIN #CollegeInjuries AS injury ON signOrder.BPlayerId = injury.BPlayerId