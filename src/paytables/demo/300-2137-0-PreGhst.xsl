<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl"/>
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl"/>

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />
			
			<!--
			TEMPLATE
			Match:
			-->
			<x:template match="/">
				<x:apply-templates select="*"/>
				<x:apply-templates select="/output/root[position()=last()]" mode="last"/>
				<br/>
			</x:template>
			<lxslt:component prefix="my-ext" functions="formatJson retrievePrizeTable">
				<lxslt:script lang="javascript">
					<![CDATA[
function formatJson(jsonContext, translations, prizeValues, prizeNamesDesc) {
	var scenario = getScenario(jsonContext);
	var tranMap = parseTranslations(translations);
	var prizeMap = parsePrizes(prizeNamesDesc, prizeValues);
	return doFormatJson(scenario, tranMap, prizeMap);

}
function ScenarioConvertor(scenario, currency) {
	this.scenario = scenario;
	this.baseScenarioSplit = this.scenario.split("|")[0].split(",");
	this.extraTurns = this.getExtraTurns();
	//this.extraTurns = this.baseScenarioSplit.length - 5;
	this.currency = currency;
}
ScenarioConvertor.prototype.getExtraTurns = function () {
	var totalTurns = 0;
	var baseScenarioSplit = this.baseScenarioSplit;
	for (var i = 0; i < baseScenarioSplit.length; i++) {
		if (/\w/.test(baseScenarioSplit[i])) {
			totalTurns++;
		}
	}
	return totalTurns - 5 > 0 ? totalTurns - 5 : "No";
};
ScenarioConvertor.prototype.generateOutCome = function () {
	var len = this.baseScenarioSplit.length;
	var outComeTable = [];
	for (var i = 0; i < len - 1; i++) {
		var row = [];
		var subStrFrom =  - (1 + i); // -1,-2,-3
		for (var j = 0; j < len; j++) {
			var str = this.baseScenarioSplit[j].substr(subStrFrom, 1);
			if (str !== '.') {
				row.push(this.baseScenarioSplit[j].substr(subStrFrom, 1));
			} else {
				row.push('');
			}
		}
		outComeTable.push(row);
	}
	return outComeTable;
}

ScenarioConvertor.prototype.getTotalMovesAndPaytable = function (stepsMap, prizeMap, prizeBoat) {
	var outComeTable = this.generateOutCome();
	var movesAndPaytable = [];
	var currency = this.currency;
	for (var i = 0; i < outComeTable.length; i++) {
		var steps = 0,
		multiply = 1,
		winPrize = 0;
		var winPrize;
		for (var j = 0; j < outComeTable[i].length; j++) {
			if (isNaN(outComeTable[i][j])) {
				if (outComeTable[i][j] === 'X') {
					multiply *= 2;
				}
			} else {
				steps += Number(outComeTable[i][j]);
			}
		}
		movesAndPaytable.push({
			"steps": steps,
			"multiply": multiply
		});
	}

	var pickBonusScenario = this.scenario.split("|")[1].split(':');
	var winIndex = pickBonusScenario[0];
	if (winIndex === '0') {}
	else {
		var boatMap = {
			'A': '6',
			'B': '5',
			'C': '4',
			'D': '3',
			'E': '2',
			'F': '1'
		};
		var winData = pickBonusScenario[1].split(',')[winIndex - 1];
		var charAt_0 = winData.charAt(0);
		if (charAt_0 === 'A' || charAt_0 === 'B' || charAt_0 === 'C' || charAt_0 === 'D' || charAt_0 === 'E' || charAt_0 === 'F') {
			var charAt_1 = winData.charAt(1);
			var index = boatMap[charAt_0] - 1;
			if (isNaN(charAt_1)) {
				movesAndPaytable[index].multiply *= 2;
			} else {
				movesAndPaytable[index].steps += Number(charAt_1);
			}
		}
	}

	var shellBonusScenario = this.scenario.split("|")[2].split(':');
	var winIndex = shellBonusScenario[0];
	if (winIndex === '0') {}
	else {
		var boatMap = {
			'A': '6',
			'B': '5',
			'C': '4',
			'D': '3',
			'E': '2',
			'F': '1'
		};
		var winData = shellBonusScenario[1].split(',')[winIndex - 1];
		var charAt_0 = winData.charAt(0);
		if (charAt_0 === 'A' || charAt_0 === 'B' || charAt_0 === 'C' || charAt_0 === 'D' || charAt_0 === 'E' || charAt_0 === 'F') {
			var charAt_1 = winData.charAt(1);
			var index = boatMap[charAt_0] - 1;
			if (isNaN(charAt_1)) {
				movesAndPaytable[index].multiply *= 2;
			} else {
				movesAndPaytable[index].steps += Number(charAt_1);
			}
		}
	}

	movesAndPaytable.forEach(function (item, index) {
		var winPrize = '--';
		if (item.steps >= stepsMap[index]) {
			var payNumSplit = prizeMap[prizeBoat[index]].match(/\d+/g);
			var strNum = '';
			var payNum;
			payNumSplit.forEach(function (item, index) {
				if (index === payNumSplit.length - 1) {
					strNum += '.';
				}
				strNum += item;
			});
			payNum = Number.prototype.toFixed.call(strNum * (item.multiply), 2);
			(function(num){
				num = num.toString();
				var intPart=num.substring(0,num.indexOf('.'));
				var floatPart=num.substring(num.indexOf('.'));
				var str='';
				while(intPart.length>3){
					var interIndex = intPart.length-3;
					str=','+intPart.substring(interIndex)+str;
					intPart=intPart.substring(0,interIndex);
				}
				str = intPart+str;
				payNum = str+floatPart;
			})(payNum);
			winPrize = currency + payNum;
		}
		item['winPrize'] = winPrize;
	});

	return movesAndPaytable;
}
ScenarioConvertor.prototype.getGemInstantWin = function () {
	var baseGameScenario = this.scenario.split("|")[0];
	var repeatNum = 0;
	for (var i = 0; i < baseGameScenario.length; i++) {
		if (baseGameScenario.substr(i, 1) === "G") {
			repeatNum++;
		}
	}
	return repeatNum;
}

ScenarioConvertor.prototype.getBonusResult = function (boatMap, type, tranMap, prizeMap) {
	var bonusScenario;
	if (type === 1) {
		bonusScenario = this.scenario.split("|")[1].split(':');
	} else {
		bonusScenario = this.scenario.split("|")[2].split(':');
	}
	var winIndex = bonusScenario[0];
	if (winIndex === '0') {
		return 'No';
	} else {
		var winData = bonusScenario[1].split(',')[winIndex - 1];
		var charAt_0 = winData.charAt(0);
		switch (charAt_0) {
		case 'I':
			winEinstant = winData.charAt(2) === "1" ? prizeMap.IW1 : prizeMap.IW2;
			return winEinstant;
		case '+':
			return tranMap.extra;
		case 'G':
			return tranMap.G;
		case 'O':
			return tranMap.W;
		case 'H':
			return tranMap.H;
		default: {
				var charAt_1 = winData.charAt(1);
				if (isNaN(charAt_1)) {
					return 'Row' + boatMap[charAt_0] + ': 2X';
				} else {
					return 'Row' + boatMap[charAt_0] + ': ' + charAt_1;
				}
			}
		}
	}
}

function doFormatJson(scenario, tranMap, prizeMap) {
	var indicator = scenario.split("|")[0];
	var playGrid = scenario.split("|")[1];
	var boatMap = {
		'A': '6',
		'B': '5',
		'C': '4',
		'D': '3',
		'E': '2',
		'F': '1'
	};
	var stepsMap = [10, 11, 12, 13, 14, 15];
	var prizeBoat = {
		'0': 'F',
		'1': 'E',
		'2': 'D',
		'3': 'C',
		'4': 'B',
		'5': 'A'
	};
	var currency = prizeMap.A.match(/\D+/)[0];
	var result = new ScenarioConvertor(scenario, currency);
	var gemWinValue = 'No';
	if (result.getGemInstantWin() > 2) {
		gemWinValue = prizeMap['G' + result.getGemInstantWin()];
	}
	var r = [];
	r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
	r.push('<tr>');
	r.push('<td class="tablehead" width="100%" colspan="8">');
	r.push(tranMap.outcomeLabel);
	r.push('</td>');
	r.push('</tr>');

	r.push('<tr>');
	r.push('<td class="tablebody" width="23%">');
	r.push('</td>');
	for (var i = 1; i < 8; i++) {
		r.push('<td class="tablebody" width="11%">');
		r.push(tranMap.turn + " " + i);
		r.push('</td>');
	}
	r.push('</tr>');
	result.generateOutCome().forEach(function (row, index) {
		r.push('<tr>');
		r.push('<td class="tablebody" width="23%">');
		switch (index) {
		case 0:
			r.push(tranMap.row + ' 1');
			break;
		case 1:
			r.push(tranMap.row + ' 2');
			break;
		case 2:
			r.push(tranMap.row + ' 3');
			break;
		case 3:
			r.push(tranMap.row + ' 4');
			break;
		case 4:
			r.push(tranMap.row + ' 5');
			break;
		case 5:
			r.push(tranMap.row + ' 6');
			break;
		default:
			break;
		}
		r.push('</td>');
		row.forEach(function (col) {
			r.push('<td class="tablebody" width="11%">');
			if (isNaN(col)) {
				switch (col) {
				case '+':
					col = tranMap.extra;
					break;
				case 'X':
					col = '2X';
					break;
				case 'G':
					col = tranMap.G;
					break;
				case 'H':
					col = tranMap.H;
					break;
				default:
					col = tranMap.W;
					break;
				}
			}
			r.push(col);
			r.push('</td>');
		});
		r.push('</tr>');
	});
	r.push('<tr>');
	r.push('<td class="tablebody" width="23%">');
	r.push(tranMap.extraSpin);
	r.push('</td>');
	r.push('<td class="tablebody" width="23%" colspan="7">');
	r.push(result.extraTurns);
	r.push('</td>');
	r.push('</tr>');
	r.push('<tr>');
	r.push('<td class="tablebody" width="23%">');
	r.push(tranMap.gemInstantWin);
	r.push('</td>');
	r.push('<td class="tablebody" width="23%" colspan="7">');
	r.push(gemWinValue);
	r.push('</td>');
	r.push('</tr>');
	r.push('</table>');

	r.push('<div width="100%" class="blankStyle">');
	r.push('</div>');

	r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
	r.push('<tr>');
	r.push('<td class="tablehead" width="100%" colspan="8">');
	r.push(tranMap.shellBonusTitle);
	r.push('</td>');
	r.push('</tr>');

	r.push('<tr>');
	r.push('<td class="tablebody" width="23%">');
	r.push(tranMap.bonusResult);
	r.push('</td>');
	r.push('<td class="tablebody" width="23%" colspan="7">');
	r.push(result.getBonusResult(boatMap, 1, tranMap, prizeMap));
	r.push('</td>');
	r.push('</tr>');

	r.push('</table>');

	r.push('<div width="100%" class="blankStyle">');
	r.push('</div>');

	r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
	r.push('<tr>');
	r.push('<td class="tablehead" width="100%" colspan="8">');
	r.push(tranMap.wheelBonusTitle);
	r.push('</td>');
	r.push('</tr>');

	r.push('<tr>');
	r.push('<td class="tablebody" width="23%">');
	r.push(tranMap.bonusResult);
	r.push('</td>');
	r.push('<td class="tablebody" width="23%" colspan="7">');
	r.push(result.getBonusResult(boatMap, 2, tranMap, prizeMap));
	r.push('</td>');
	r.push('</tr>');

	r.push('</table>');

	r.push('<div width="100%" class="blankStyle">');
	r.push('</div>');
	r.push('<table border="0" cellpadding="2" cellspacing="1" width="50%" class="gameDetailsTable" style="table-layout:fixed">');
	r.push('<tr>');
	r.push('<td class="tablebody" width="23%">');
	r.push('</td>');
	r.push('<td class="tablebody" width="11%">');
	r.push(tranMap.totalMoves);
	r.push('</td>');
	r.push('<td class="tablebody" width="11%">');
	r.push(tranMap.targetMoves);
	r.push('</td>');
	r.push('<td class="tablebody" width="11%">');
	r.push(tranMap.winPrizeLabel);
	r.push('</td>');
	r.push('</tr>');

	result.getTotalMovesAndPaytable(stepsMap, prizeMap, prizeBoat).forEach(function (item, index) {
		r.push('<tr>');
		r.push('<td class="tablebody" width="23%">');
		switch (index) {
		case 0:
			r.push(tranMap.row + ' 1');
			break;
		case 1:
			r.push(tranMap.row + ' 2');
			break;
		case 2:
			r.push(tranMap.row + ' 3');
			break;
		case 3:
			r.push(tranMap.row + ' 4');
			break;
		case 4:
			r.push(tranMap.row + ' 5');
			break;
		case 5:
			r.push(tranMap.row + ' 6');
			break;
		default:
			break;
		}
		r.push('</td>');
		r.push('<td class="tablebody">');
		r.push(item.steps);
		r.push('</td>');
		r.push('<td class="tablebody">');
		r.push(stepsMap[index]);
		r.push('</td>');
		r.push('<td class="tablebody">');
		r.push(item.winPrize);
		r.push('</td>');
		r.push('</tr>');
	});

	r.push('</table>');

	r.push('<div width="100%" class="blankStyle">');
	r.push('</div>');
	return r.join('');
}
function getScenario(jsonContext) {
	var jsObj = JSON.parse(jsonContext);
	var scenario = jsObj.scenario;
	scenario = scenario.replace(/\0/g, '');
	return scenario;
}
function parsePrizes(prizeNamesDesc, prizeValues) {
	var prizeNames = (prizeNamesDesc.substring(1)).split(',');
	var convertedPrizeValues = (prizeValues.substring(1)).split('|');
	var map = [];
	for (var idx = 0; idx < prizeNames.length; idx++) {
		map[prizeNames[idx]] = convertedPrizeValues[idx];
	}
	return map;
}
function parseTranslations(translationNodeSet) {
	var map = [];
	var list = translationNodeSet.item(0).getChildNodes();
	for (var idx = 1; idx < list.getLength(); idx++) {
		var childNode = list.item(idx);
		if (childNode.name == "phrase") {
			map[childNode.getAttribute("key")] = childNode.getAttribute("value");
		}
	}
	return map;
}
					]]>
				</lxslt:script>
			</lxslt:component>
			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit"/>
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount"/>
								<x:with-param name="code" select="/output/denom/currencycode"/>
								<x:with-param name="locale" select="//translation/@language"/>
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit"/>
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode"/>
								<x:with-param name="locale" select="//translation/@language"/>
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>
		
			<!--
			TEMPLATE
			Match:		digested/game
			-->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="History.Detail" />
				</x:if>
				<x:if test="OutcomeDetail/Stage = 'Wager' and OutcomeDetail/NextStage = 'Wager'">
					<x:call-template name="History.Detail" />
				</x:if>
			</x:template>
		
			<!--
			TEMPLATE
			Name:		Wager.Detail (base game)
			-->
			<x:template name="History.Detail">
				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value"/>
							<x:value-of select="': '"/>
							<x:value-of select="OutcomeDetail/RngTxnId"/>
						</td>
					</tr>
				</table>
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>
				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>
				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>
		
			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>
			
			<x:template match="text()"/>
			
		</x:stylesheet>
	</xsl:template>
	
	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
		    <clickcount>
		        <x:value-of select="."/>
		    </clickcount>
		</x:template>
		<x:template match="*|@*|text()">
		    <x:apply-templates/>
		</x:template>
	</xsl:template>
	
</xsl:stylesheet>
